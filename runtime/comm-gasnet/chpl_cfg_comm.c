#include <signal.h>
#include <stdint.h>
#include <stdlib.h>
#include "chplrt.h"
#include "chplcomm.h"
#include "chplmem.h"
#include "chplsys.h"
#include "chplthreads.h"
#include "error.h"

#define GASNET_PAR 1
#include "gasnet.h"

static int chpl_comm_diagnostics = 0; // set via startCommDiagnostics
static chpl_mutex_t chpl_comm_diagnostics_lock;
static int chpl_comm_gets = 0;
static int chpl_comm_puts = 0;
static int chpl_comm_forks = 0;
static int chpl_comm_nb_forks = 0;
static int chpl_verbose_comm = 0;     // set via startVerboseComm
static int chpl_comm_no_debug_private = 0;



//
// The following macro is from the GASNet test.h distribution
//
#define GASNET_Safe(fncall) do {                                        \
    int _retval;                                                        \
    if ((_retval = fncall) != GASNET_OK) {                              \
      fprintf(stderr, "ERROR calling: %s\n"                             \
              " at: %s:%i\n"                                            \
              " error: %s (%s)\n",                                      \
              #fncall, __FILE__, __LINE__,                              \
              gasnet_ErrorName(_retval), gasnet_ErrorDesc(_retval));    \
      fflush(stderr);                                                   \
      gasnet_exit(_retval);                                             \
    }                                                                   \
  } while(0)

typedef struct {
  int     caller;
  int    *ack;
  _Bool   serial_state; // true if not allowed to spawn new threads
  func_p  fun;
  int     arg_size;
  char    arg[0];       // variable-sized data here
} fork_t;

typedef struct {
  void* addr;    // address to put data
  int size;      // size of data
  char data[0];  // data
} put_t;

//
// AM functions
//
#define FORK_NB    128    // (non-blocking) async fork 
#define FORK       129    // synchronous fork
#define SIGNAL     130    // ack of synchronous fork
#define PUTDATA    131    // put data at addr (used for private broadcast)
#define FORK_LARGE 132    // synchronous fork with an argument too big for FORK

static void fork_nb_wrapper(fork_t *f) {
  if (f->arg_size)
    (*(f->fun))(&(f->arg));
  else
    (*(f->fun))(0);
  chpl_free(f, 0, 0);
}

// AM non-blocking fork handler, medium sized, receiver side
static void AM_fork_nb(gasnet_token_t  token,
                        void           *buf,
                        size_t          nbytes) {
  fork_t *f;

  f = (fork_t*)chpl_malloc(nbytes, sizeof(char), "AM_fork_nb info", 0, 0);
  bcopy(buf, f, nbytes);
  chpl_begin((chpl_threadfp_t)fork_nb_wrapper, (chpl_threadarg_t)f,
             true, f->serial_state, NULL);
}

static void fork_wrapper(fork_t *f) {
  if (f->arg_size)
    (*(f->fun))(&(f->arg));
  else
    (*(f->fun))(0);
  GASNET_Safe(gasnet_AMRequestMedium0(f->caller,
                                      SIGNAL,
                                      &(f->ack),
                                      sizeof(f->ack)));
  chpl_free(f, 0, 0);
}

static void fork_large_wrapper(fork_t* f) {
  void* arg = chpl_malloc(1, f->arg_size, "fork argument", 0, 0);

  _chpl_comm_get(arg, f->caller, *(void**)f->arg, f->arg_size, 0, "fork large");
  (*(f->fun))(arg);
  GASNET_Safe(gasnet_AMRequestMedium0(f->caller,
                                      SIGNAL,
                                      &(f->ack),
                                      sizeof(f->ack)));
  chpl_free(f, 0, 0);
  chpl_free(arg, 0, 0);
}

// AM fork handler, medium sized, receiver side
static void AM_fork(gasnet_token_t  token,
                    void           *buf,
                    size_t          nbytes) {
  fork_t *f;

  f = (fork_t*)chpl_malloc(nbytes, sizeof(char), "AM_fork info", 0, 0);
  bcopy(buf, f, nbytes);
  chpl_begin((chpl_threadfp_t)fork_wrapper, (chpl_threadarg_t)f,
             true, f->serial_state, NULL);
}

static void AM_fork_large(gasnet_token_t  token, void* buf, size_t nbytes) {
  fork_t* f = chpl_malloc(1, nbytes, "large fork pointer", 0, 0);
  bcopy(buf, f, nbytes);

  chpl_begin((chpl_threadfp_t)fork_large_wrapper, (chpl_threadarg_t)f,
             true, f->serial_state, NULL);
}


// AM signal handler, medium sized, receiver side
static void AM_signal(gasnet_token_t  token,
                      void           *buf,
                      size_t          nbytes) {
  int **done = (int**)buf;
  **done = 1;
}

static void AM_putdata(gasnet_token_t  token,
                       void           *buf,
                       size_t          nbytes) {
  put_t* pbp = buf;
  memcpy(pbp->addr, pbp->data, pbp->size);
}

static gasnet_handlerentry_t ftable[] = {
  {FORK,    AM_fork},    // fork remote thread synchronously
  {FORK_NB, AM_fork_nb}, // fork remote thread asynchronously
  {SIGNAL,  AM_signal},  // set remote (int) condition
  {PUTDATA, AM_putdata}, // put data at addr (used for private broadcast)
  {FORK_LARGE, AM_fork_large}
};

static gasnet_seginfo_t seginfo_table[1024];

//
// Chapel interface starts here
//

int32_t _chpl_comm_getMaxThreads(void) {
  return GASNETI_MAX_THREADS-1;
}

int32_t _chpl_comm_maxThreadsLimit(void) {
  return GASNETI_MAX_THREADS-1;
}

static int done = 0;

static void polling(void* x) {
  GASNET_BLOCKUNTIL(done);
}

void _chpl_comm_init(int *argc_p, char ***argv_p) {
  pthread_t polling_thread;
  int status;

  gasnet_init(argc_p, argv_p);
  _localeID = gasnet_mynode();
  _numLocales = gasnet_nodes();
  GASNET_Safe(gasnet_attach(ftable, 
                            sizeof(ftable)/sizeof(gasnet_handlerentry_t),
                            gasnet_getMaxLocalSegmentSize(),
                            0));
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
  GASNET_Safe(gasnet_getSegmentInfo(seginfo_table, 1024));
#endif

  gasnet_set_waitmode(GASNET_WAIT_BLOCK);

  //
  // Start polling thread on locale 0.  (On other locales, main enters
  // into a barrier wait, so the polling thread is unnecessary.)
  //
  // This should call a special function in the threading interface
  // but we have not yet initialized chapel threads!
  //
  if (_localeID == 0) {
    status = pthread_create(&polling_thread, NULL, (chpl_threadfp_t)polling, 0);
    if (status)
      chpl_internal_error("unable to start polling thread for gasnet");
    pthread_detach(polling_thread);
  }
}

//
// No support for gdb for now
//
int _chpl_comm_run_in_gdb(int argc, char* argv[], int gdbArgnum, int* status) {
  return 0;
}

void _chpl_comm_rollcall(void) {
  chpl_mutex_init(&chpl_comm_diagnostics_lock);
  chpl_msg(2, "executing on locale %d of %d locale(s): %s\n", _localeID, 
           _numLocales, chpl_localeName());
}

void _chpl_comm_init_shared_heap(void) {
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
  void* heapStart = numGlobalsOnHeap*sizeof(void*) + (char*)seginfo_table[_localeID].addr;
  size_t heapSize = seginfo_table[_localeID].size - numGlobalsOnHeap*sizeof(void*);
  initHeap(heapStart, heapSize);
#else
  initHeap(NULL, 0);
#endif
}

void _chpl_comm_alloc_registry(int numGlobals) {
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
  _global_vars_registry = numGlobals == 0 ? NULL : seginfo_table[_localeID].addr;
#else
  _global_vars_registry = _global_vars_registry_static;
#endif
}

void _chpl_comm_broadcast_global_vars(int numGlobals) {
  int i;
  if (_localeID != 0) {
    for (i = 0; i < numGlobals; i++) {
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
      _chpl_comm_get(_global_vars_registry[i], 0,
                     &((void**)seginfo_table[0].addr)[i], sizeof(void*), 0, "");
#else
      _chpl_comm_get(_global_vars_registry[i], 0,
                     &_global_vars_registry[i], sizeof(void*), 0, "");
#endif
    }
  }
}

void _chpl_comm_broadcast_private(void* addr, int size) {
  int locale;
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
  int payloadSize = size + sizeof(put_t);
  put_t* pbp = chpl_malloc(1, payloadSize, "private broadcast payload", 0, 0);
  pbp->addr = addr;
  pbp->size = size;
  memcpy(pbp->data, addr, size);
#endif

  for (locale = 0; locale < _numLocales; locale++) {
    if (locale != _localeID) {
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
      GASNET_Safe(gasnet_AMRequestMedium0(locale, PUTDATA, pbp, payloadSize));
#else
      _chpl_comm_put(addr, locale, addr, size, 0, "");
#endif
    }
  }
#if defined(GASNET_SEGMENT_FAST) || defined(GASNET_SEGMENT_LARGE)
  chpl_free(pbp, 0, 0);
#endif
}

void _chpl_comm_barrier(const char *msg) {
  if (chpl_verbose_comm && !chpl_comm_no_debug_private)
    printf("%d: barrier for '%s'\n", _localeID, msg);
  gasnet_barrier_notify(0, GASNET_BARRIERFLAG_ANONYMOUS);
  GASNET_Safe(gasnet_barrier_wait(0, GASNET_BARRIERFLAG_ANONYMOUS));
}

static void _chpl_comm_exit_common(int status) {
  int* ack = &done;

  if (_localeID == 0) {
    GASNET_Safe(gasnet_AMRequestMedium0(_localeID,
                                        SIGNAL,
                                        &ack,
                                        sizeof(ack)));
  }
  gasnet_exit(status);
}

void _chpl_comm_exit_all(int status) {
  _chpl_comm_exit_common(status);
}

void _chpl_comm_exit_any(int status) {
  _chpl_comm_exit_common(status);
}

void  _chpl_comm_put(void* addr, int32_t locale, void* raddr, int32_t size, int ln, _string fn) {
  if (_localeID == locale) {
    bcopy(addr, raddr, size);
  } else {
    if (chpl_verbose_comm && !chpl_comm_no_debug_private)
      printf("%d: %s:%d: remote put to %d\n", _localeID, fn, ln, locale);
    if (chpl_comm_diagnostics && !chpl_comm_no_debug_private) {
      chpl_mutex_lock(&chpl_comm_diagnostics_lock);
      chpl_comm_puts++;
      chpl_mutex_unlock(&chpl_comm_diagnostics_lock);
    }
    gasnet_put(locale, raddr, addr, size); // node, dest, src, size
  }
}

void  _chpl_comm_get(void* addr, int32_t locale, void* raddr, int32_t size, int ln, _string fn) {
  if (_localeID == locale) {
    bcopy(raddr, addr, size);
  } else {
    if (chpl_verbose_comm && !chpl_comm_no_debug_private)
      printf("%d: %s:%d: remote get from %d\n", _localeID, fn, ln, locale);
    if (chpl_comm_diagnostics && !chpl_comm_no_debug_private) {
      chpl_mutex_lock(&chpl_comm_diagnostics_lock);
      chpl_comm_gets++;
      chpl_mutex_unlock(&chpl_comm_diagnostics_lock);
    }
    gasnet_get(addr, locale, raddr, size); // dest, node, src, size
  }
}

void  _chpl_comm_fork_nb(int locale, func_p f, void *arg, int arg_size) {
  fork_t *info;
  int           info_size;

  info_size = sizeof(fork_t) + arg_size;
  info = (fork_t*) chpl_malloc(info_size, sizeof(char), "_chpl_comm_fork_nb info", 0, 0);
  info->caller = _localeID;
  info->serial_state = chpl_get_serial();
  info->fun = f;
  info->arg_size = arg_size;
  if (arg_size)
    bcopy(arg, &(info->arg), arg_size);
  if (_localeID == locale) {
    chpl_begin((chpl_threadfp_t)fork_nb_wrapper, (chpl_threadarg_t)info,
               false, info->serial_state, NULL);
  } else {
    if (chpl_verbose_comm && !chpl_comm_no_debug_private)
      printf("%d: remote non-blocking thread created on %d\n", _localeID, locale);
    if (chpl_comm_diagnostics && !chpl_comm_no_debug_private) {
      chpl_mutex_lock(&chpl_comm_diagnostics_lock);
      chpl_comm_nb_forks++;
      chpl_mutex_unlock(&chpl_comm_diagnostics_lock);
    }
    GASNET_Safe(gasnet_AMRequestMedium0(locale, FORK_NB, info, info_size));
    chpl_free(info, 0, 0);
  }
}

void  _chpl_comm_fork(int locale, func_p f, void *arg, int arg_size) {
  fork_t* info;
  int     info_size;
  int     done;
  int     passArg = sizeof(fork_t) + arg_size <= gasnet_AMMaxMedium();

  if (_localeID == locale) {
    (*f)(arg);
  } else {
    if (chpl_verbose_comm && !chpl_comm_no_debug_private)
      printf("%d: remote thread created on %d\n", _localeID, locale);
    if (chpl_comm_diagnostics && !chpl_comm_no_debug_private) {
      chpl_mutex_lock(&chpl_comm_diagnostics_lock);
      chpl_comm_forks++;
      chpl_mutex_unlock(&chpl_comm_diagnostics_lock);
    }

    if (passArg) {
      info_size = sizeof(fork_t) + arg_size;
    } else {
      info_size = sizeof(fork_t) + sizeof(void*);
    }
    info = chpl_malloc(1, info_size, "_chpl_comm_fork info", 0, 0);
    info->caller = _localeID;
    info->ack = &done;
    info->serial_state = chpl_get_serial();
    info->fun = f;
    info->arg_size = arg_size;

    done = 0;

    if (passArg) {
      if (arg_size)
        bcopy(arg, &(info->arg), arg_size);
      GASNET_Safe(gasnet_AMRequestMedium0(locale, FORK, info, info_size));
      GASNET_BLOCKUNTIL(1==done);
    } else {
      bcopy(&arg, &(info->arg), sizeof(void*));
      GASNET_Safe(gasnet_AMRequestMedium0(locale, FORK_LARGE, info, info_size));
      GASNET_BLOCKUNTIL(1==done);
    }
    chpl_free(info, 0, 0);
  }
}

void chpl_startVerboseComm() {
  chpl_verbose_comm = 1;
  chpl_comm_no_debug_private = 1;
  _chpl_comm_broadcast_private(&chpl_verbose_comm, sizeof(int));
  chpl_comm_no_debug_private = 0;
}

void chpl_stopVerboseComm() {
  chpl_verbose_comm = 0;
  chpl_comm_no_debug_private = 1;
  _chpl_comm_broadcast_private(&chpl_verbose_comm, sizeof(int));
  chpl_comm_no_debug_private = 0;
}

void chpl_startVerboseCommHere() {
  chpl_verbose_comm = 1;
}

void chpl_stopVerboseCommHere() {
  chpl_verbose_comm = 0;
}

void chpl_startCommDiagnostics() {
  chpl_comm_diagnostics = 1;
  chpl_comm_no_debug_private = 1;
  _chpl_comm_broadcast_private(&chpl_comm_diagnostics, sizeof(int));
  chpl_comm_no_debug_private = 0;
}

void chpl_stopCommDiagnostics() {
  chpl_comm_diagnostics = 0;
  chpl_comm_no_debug_private = 1;
  _chpl_comm_broadcast_private(&chpl_comm_diagnostics, sizeof(int));
  chpl_comm_no_debug_private = 0;
}

void chpl_startCommDiagnosticsHere() {
  chpl_comm_diagnostics = 1;
}

void chpl_stopCommDiagnosticsHere() {
  chpl_comm_diagnostics = 0;
}

int32_t chpl_numCommGets(void) {
  return chpl_comm_gets;
}

int32_t chpl_numCommPuts(void) {
  return chpl_comm_puts;
}

int32_t chpl_numCommForks(void) {
  return chpl_comm_forks;
}

int32_t chpl_numCommNBForks(void) {
  return chpl_comm_nb_forks;
}
