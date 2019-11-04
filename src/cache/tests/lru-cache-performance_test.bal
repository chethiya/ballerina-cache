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
import ballerina/lang.'int;
import ballerina/test;

int putQ = 1000000;
int getQ = 1000000;

function testKeys(string[] keys, int frequentKeysCount) {
  // boolean[frequentKeysCount] found; // not being able to set inital size of array with initial values is pain
  boolean[] found = [];
  int i=0;
  while (i < frequentKeysCount) {
    found.push(false);
    i += 1;
  }
  i = 0;
  int count = 0;
  while (i < (frequentKeysCount * 2 - 1) && count < frequentKeysCount) {
    int value = <int>('int:fromString(keys[i]));
    if (value < frequentKeysCount) {
      if (found[value]) {
        break;
      }
      found[value] = true;
      count += 1;
    }
    i += 1;
  }
  test:assertEquals(count, frequentKeysCount, "Expected keys are not at the front of the list. Here are the keys" + keys.toJsonString());
}

function simulateGetForPerformance(@untainted LRUCache cache) {
  int hitRate = 0;
  int i = 0;
  int rangeEndValue = cache.capacity() / 10;
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
  io:println("Worker time is ", curTime - startTime, " and hit rate is ", hitRate, " which started at ", started);
}

public function evaluatePerformance(int cacheSize) {
  io:println("Testing performance with cache size ", cacheSize, "...");
  LRUCache cache =  new(cacheSize, 3600000);

  int startTime = time:currentTime().time;
  int i = 0;
  int hitRate = 0;
  int rangeEndValue = cacheSize/10;
  if (rangeEndValue == 0) {
    rangeEndValue = 1;
  }

  fork {
    worker w1 {
      simulateGetForPerformance(cache);
    }
    worker w2 {
      simulateGetForPerformance(cache);
    }
    worker w3 {
      simulateGetForPerformance(cache);
    }
    worker w4 {
      simulateGetForPerformance(cache);
    }
  }

  while (i < putQ) {
    string key = i.toString();
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
  io:println("Cache put time is ", curTime - startTime, " and hit rate is ", hitRate);
  _ = wait {w1, w2, w3, w4};
  int endTime = time:currentTime().time;
  testKeys(cache.keys(), rangeEndValue);
  io:println("Total time: ", endTime-startTime);
}