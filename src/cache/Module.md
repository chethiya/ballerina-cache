# LRUCache

This is an LRU Cache implementation.

This can be used as an alternative to [Cache in Stadnard Library](https://ballerina.io/learn/api-docs/ballerina/cache/index.html) which has a sub-optimal time complexity. You can find the issue regarding the sub-optimality [here](https://github.com/ballerina-platform/ballerina-lang/issues/19487).

Also you can find a detailed comparison between two implementaions [here in my blog post](http://chethiya.github.io/ballerina-lru-cache.html).

One of the key differences between this implementaion and the Stdlib Cache is the  removal of evication factor which is not needed. Also this implemeantion supports the option to expire based on last access time, or last PUT time (ignoreing GET). That is quite useful in many practical scenarios where you have to cache page/search results for a fixed period since PUT operation, irrespective of how frequently you read those results.