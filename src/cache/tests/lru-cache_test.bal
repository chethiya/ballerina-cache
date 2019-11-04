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

function expiryTimeTest(
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

# Test function

@test:Config {
  before: "beforeFunc",
  after: "afterFunc"
}

function testFunction() {
  io:println("I'm in test function!");
  // io:println(expiryTimeTest(400, false));
  // io:println(expiryTimeTest(400, true));
  test:assertEquals(expiryTimeTest(400, false), <[string[], int]>[<string[]>["c", "b"], 2]);
  test:assertEquals(expiryTimeTest(400, true), <[string[], int]>[<string[]>["a", "c", "b"], 3]);

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
