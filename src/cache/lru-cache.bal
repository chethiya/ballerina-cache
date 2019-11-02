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

import ballerina/time;

type CacheItem object {
  any data;
  string key;
  int lastAccessTime;
  CacheItem? prev;
  CacheItem? next;

  function __init(any data, string key) {
    self.data = data;
    self.key = key;
    self.lastAccessTime = 0;
    self.prev = ();
    self.next = ();
  }
};

public type LRUCache object {
  private int capacity;
  private int expiryTime; // in nanoseconds, assuming program won't run for 100 years!
  private boolean updateLastAccessTimeOnGet;

  private map<CacheItem> cache = {};
  CacheItem? head = ();
  CacheItem? tail = ();
  int size = 0;

  # Create an LRU cache
  #
  # + capacity - Number of entries allocated for the cache
  # + expiryTimeInMillis - If time since last access time of an entry is greater than this value then those entries will be discarded from the cache
  # + updateLastAccessTimeOnGet - Update the last access time of the entries even on get() method. If this is set to false last access time of the entries will only be updated on put() method. This is false by default because in most cases values you set in the cache are expected to be timed out after some time, no matter how frequently you read those cache entries.
  public function __init(
    int capacity = 100,
    int expiryTimeInMillis = 0,
    boolean updateLastAccessTimeOnGet = false
  ) {
    self.capacity = capacity;
    self.expiryTime = expiryTimeInMillis * 1000000;
    self.updateLastAccessTimeOnGet = updateLastAccessTimeOnGet;
  }

  // Linked list operations
  private function removeFromLinkedList(CacheItem item) {
    if (item.prev is ()) {
      self.head = item.next;
    } else {
      CacheItem i = <CacheItem>item.prev; // compiler needs to improve here
      i.next = item.next;
    }

    if (item.next is ()) {
      self.tail = item.prev;
    } else {
      CacheItem i = <CacheItem>item.next;
      i.prev = item.prev;
    }
    item.next = ();
    item.prev = ();
  }

  private function addToHead(CacheItem item, boolean isGet = false) {
    if (self.head is ()) {
      self.head = item;
      self.tail = item;
    } else {
      item.next = self.head;
      // Can't do either below:
      // self.head.prev = item;  // compiler needs to improve to detect if above
      // (<CacheItem>(self.head)).prev = item;  // compiler needs to improve

      // So doing it this way
      CacheItem h = <CacheItem>self.head;
      h.prev = item;

      self.head = item;
    }
    if (!isGet || self.updateLastAccessTimeOnGet) {
      item.lastAccessTime = time:nanoTime();
    }
  }

  // evicting least recently used item when the capicity is reached
  private function evictLRUItem() {
    if (self.tail is ()) {
      return;
    }
    CacheItem item = <CacheItem>self.tail;
    self.removeFromLinkedList(item);
    _ = self.cache.remove(item.key);
    self.size -= 1;
  }

  private function expireLRUItems() {
    if (self.expiryTime == 0) {
      return;
    }
    int expireTime = time:nanoTime() - self.expiryTime;
    // Compiler needs to improve

    // while (!(self.tail is ()) && self.tail.lastAccessTime < expireTime) {
    // while (!(self.tail is ()) && (<CacheItem>self.tail).lastAccessTime < expireTime) {
    while (!(self.tail is ())) {
      CacheItem t = <CacheItem>self.tail;
      if (t.lastAccessTime >= expireTime) {
        return;
      }
      self.evictLRUItem();
    }
  }

  # Check whether key is valid cache entry without updating access time
  # You can use get() method if access time need to be updated.
  # () will be returned.
  #
  # + key - Key of the cache entry
  # + return - Returns whether there is valid cache entry associated with key
  public function hasKey(string key) returns boolean {
    lock {
      if (!self.cache.hasKey(key)) {
        return false;
      }
      CacheItem item = self.cache.get(key);
      if (
        self.expiryTime > 0 &&
        item.lastAccessTime < time:nanoTime() - self.expiryTime
      ) {
        // Remove item from the  cache
        self.removeFromLinkedList(item);
        _ = self.cache.remove(key);
        self.size -= 1;
        return false;
      }
      return true;
    }
  }

  public function get(string key) returns @untainted any? {
    lock {
      if (!self.cache.hasKey(key)) {
        return ();
      }
      CacheItem item = self.cache.get(key);
      // removed from the linked list to add it back to front or expire it later
      self.removeFromLinkedList(item);

      if (
        self.expiryTime > 0 &&
        item.lastAccessTime < time:nanoTime() - self.expiryTime
      ) { // item is expired
        // Get rid of current item from the cache
        _ = self.cache.remove(key);
        self.size -= 1;
        return ();
      }

      self.addToHead(item, true);
      return item.data;
    }
  }

  public function put(string key, any value) {
    lock {
      if (self.cache.hasKey(key)) {
        CacheItem item = self.cache.get(key);
        item.data = value;
        self.removeFromLinkedList(item);
        self.addToHead(item);
        return;
      }

      if (self.size == self.capacity) {
        self.evictLRUItem();
      }
      CacheItem item = new(data = value, key = key);
      self.addToHead(item);
      self.cache[key] = item;
      self.size += 1;
    }
  }

  public function remove(string key) returns any? {
    lock {
      if (!self.cache.hasKey(key)) {
        return ();
      }
      CacheItem item = self.cache.get(key);
      self.removeFromLinkedList(item);
      _ = self.cache.remove(key);
      self.size -= 1;
      return item.data;
    }
  }

  public function keys() returns string[] {
    lock {
      // Need to get rid of expired items before geting the list of keys
      self.expireLRUItems();
      return self.cache.keys();
    }
  }

  public function size() returns int {
    lock {
      // Need to get rid of expired items before geting the size
      self.expireLRUItems();
      return self.size;
    }
  }

  public function capacity() returns int {
    return self.capacity;
  }
};