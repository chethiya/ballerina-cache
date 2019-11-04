import ballerina/io;
import ballerina/test;
import ballerina/runtime;

# Before Suite Function

@test:BeforeSuite
function beforeSuiteFunc() {
  io:println("I'm the before suite function!");
}

# Before test function

function beforeFunc() {
  io:println("I'm the before function!");
}

function expiryTimeTestHelper(
  int expiryTime,
  boolean updateLastAccesssTimeOnGet
) returns @tainted [string[], int] {
  LRUCache cache = new(3, expiryTime, updateLastAccesssTimeOnGet);
  cache.put("a", 1);
  runtime:sleep(200);
  cache.put("b", 2);
  cache.put("c", 3);
  _ = cache.get("a");
  runtime:sleep(300);
  return [cache.keys(), cache.size()];
}

function expiryTimeTest() {
  test:assertEquals(expiryTimeTestHelper(400, false), <[string[], int]>[<string[]>["c", "b"], 2]);
  test:assertEquals(expiryTimeTestHelper(400, true), <[string[], int]>[<string[]>["a", "c", "b"], 3]);
}

function linkedListTest() {
  // single entry
  LRUCache cache = new (10, 0);
  test:assertEquals(cache.keys(), <string[]>[]);
  cache.put("a", 1);
  test:assertEquals(cache.keys(), <string[]>["a"]);
  cache.put("a", 1);
  test:assertEquals(cache.keys(), <string[]>["a"]);
  test:assertEquals(cache.get("a"), 1);
  test:assertEquals(cache.keys(), <string[]>["a"]);

  //two entries
  cache.put("b", 2);
  test:assertEquals(cache.keys(), <string[]>["b", "a"]);
  cache.put("b", 2);
  test:assertEquals(cache.keys(), <string[]>["b", "a"]);
  test:assertEquals(cache.get("b"), 2);
  test:assertEquals(cache.keys(), <string[]>["b", "a"]);
  test:assertEquals(cache.get("a"), 1);
  test:assertEquals(cache.keys(), <string[]>["a", "b"]);
  cache.put("b", 4);
  test:assertEquals(cache.keys(), <string[]>["b", "a"]);
  test:assertEquals(cache.get("b"), 4);
  cache.put("a", 3);
  test:assertEquals(cache.get("a"), 3);
  test:assertEquals(cache.keys(), <string[]>["a", "b"]);

  // removed one in midle of linked list
  cache.put("c", 5);
  test:assertEquals(cache.keys(), <string[]>["c", "a", "b"]);
  test:assertEquals(cache.get("b"), 4);
  test:assertEquals(cache.keys(), <string[]>["b", "c", "a"]);
  cache.put("c", 6);
  test:assertEquals(cache.keys(), <string[]>["c", "b", "a"]);
  test:assertEquals(cache.get("c"), 6);
  test:assertEquals(cache.keys(), <string[]>["c", "b", "a"]);
  test:assertEquals(cache.get("a"), 3);
  test:assertEquals(cache.keys(), <string[]>["a", "c", "b"]);
}

# Test function

@test:Config {
  before: "beforeFunc",
  after: "afterFunc"
}

function testFunction() {
  io:println("I'm in test function!");

  expiryTimeTest();
  linkedListTest();

  test:assertTrue(true, msg = "Failed!");
}

# After test function

function afterFunc() {
  io:println("I'm the after function!");
}

# After Suite Function

@test:AfterSuite
function afterSuiteFunc() {
  io:println("I'm the after suite function!");
}
