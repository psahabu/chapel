/*
 * Copyright 2004-2017 Cray Inc.
 * Other additional copyright holders may be indicated within.
 *
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef _RESOLVE_FUNCTION_H_
#define _RESOLVE_FUNCTION_H_

class AggregateType;
class FnSymbol;
class Type;

void  resolveFunction(FnSymbol* fn);

bool  isLeaderIterator(FnSymbol* fn);

bool  isStandaloneIterator(FnSymbol* fn);

void  resolveReturnType(FnSymbol* fn);

Type* getReturnedTupleType(FnSymbol*      fn,
                           AggregateType* retType);

#endif