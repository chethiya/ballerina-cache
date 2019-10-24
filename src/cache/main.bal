// MIT License

// Copyright (c) 2019 Chethiya Abeysinghe

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import ballerina/io;
import ballerina/time;
import ballerina/math;
import ballerina/runtime;

public function simpleTest() {
  LRUCache cache = new(3, 400);
  cache.put("a", 1);
  runtime:sleep(200);
  cache.put("b", 2);
  cache.put("c", 3);
  runtime:sleep(300);

  io:println("a ", cache.hasKey("a"));
  io:println("b ", cache.hasKey("b"));
  io:println("c ", cache.hasKey("c"));
  io:println("d ", cache.hasKey("d"));

  io:println(cache.keys().toJsonString());
  // io:println("a ", cache.get("a"));
  // io:println("b ", cache.get("b"));
  // io:println("c ", cache.get("c"));
  // io:println("d ", cache.get("d"));

  cache.put("a", 5);
  cache.put("d", 4);

  io:println(cache.keys().toJsonString());

  io:println("a ", cache.get("a"));
  io:println("b ", cache.get("b"));
  io:println("c ", cache.get("c"));
  io:println("d ", cache.get("d"));
}



// import ballerina/runtime;
int putQ = 1000000;
int getQ = 1000000;

function simulateGet(@untainted LRUCache cache, int cacheSize) {
  int hitRate = 0;
  int i = 0;
  int rangeEndValue = cacheSize/10;
  if (rangeEndValue == 0) {
    rangeEndValue = 1;
  }
  int started = -1;
  int startTime = time:currentTime().time;
  while (i < getQ ) {
    boolean small = (<int>math:randomInRange(0, 1)) == 0 ? true : false;
    int getIndex = <int>math:randomInRange(0, small ? rangeEndValue : getQ);
    string getKey = getIndex.toString();
    any? getValue = cache.get(getKey);
    if (getValue is int) {
      hitRate += 1;
      if (started == -1) {
        started = i;
      }
    }
    i += 1;
  }
  int curTime = time:currentTime().time;
  io:println("Worker time ", curTime - startTime, " and hit rate is ", hitRate, " which started at ", started);
}

public function evaluate(int cacheSize) {
  io:println("Testing cache size ", cacheSize);
  LRUCache cache =  new(cacheSize, 3600000);

  int startTime = time:currentTime().time;

  int i = 0;
  int hitRate = 0;
  int rangeEndValue = cacheSize/10;
  if (rangeEndValue == 0) {
    rangeEndValue = 1;
  }

  worker w1 {
    simulateGet(cache, cacheSize);
  }
  worker w2 {
    simulateGet(cache, cacheSize);
  }
  worker w3 {
    simulateGet(cache, cacheSize);
  }
  worker w4 {
    simulateGet(cache, cacheSize);
  }
  while (i < putQ) {
    // runtime:sleep(1);
    string key = i.toString();
    // io:println("putting ", i);
    cache.put(key, i);
    int getIndex = i % rangeEndValue;
    string getKey = getIndex.toString();
    any? getValue = cache.get(getKey);
    if (getValue is int) {
      hitRate += 1;
    }
    // io:println("getKey ", getKey, " hit rate ", hitRate);
    i += 1;
  }
  int curTime = time:currentTime().time;
  io:println("Cache put time ", curTime - startTime, " and hit rate is ", hitRate);
  io:println(cache.keys());
  _ = wait {w1, w2, w3, w4};
  int endTime = time:currentTime().time;

  io:println("Total time: ", endTime-startTime);

  // expected time
  // map<int> fastCache = {};

  // startTime = time:currentTime().time;
  // i = 0;
  // sum = 0;
  // while (i < q) {
  //   string key = i.toString();
  //   fastCache[key] = i;
  //   int getIndex = i - <int>math:randomInRange(0, cacheSize);
  //   if (getIndex < 0) {
  //     getIndex = 0;
  //   }
  //   string getKey = getIndex.toString();
  //   int? getValue = fastCache.get(getKey);
  //   if (getValue is int) {
  //     sum += getValue;
  //   }
  //   i += 1;
  // }
  // endTime = time:currentTime().time;

  // io:println("Cache size: ", cacheSize, " sum: ", sum, " expected time: ", endTime-startTime);

}

public function main() {
  simpleTest();

  evaluate(5);
  evaluate(10);
  evaluate(20);
  evaluate(40);
  evaluate(80);
  evaluate(160);
  evaluate(320);
  evaluate(640);
  evaluate(1000);
}