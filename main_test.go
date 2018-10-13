package main

import (
	"fmt"

	"github.com/go-redis/redis"
)

func Example() {
	pong, err := cluster.Ping().Result()
	fmt.Println(pong, err)

	err = cluster.Set("key", "value", 0).Err()
	if err != nil {
		fmt.Println(err)
	}

	val, err := cluster.Get("key").Result()
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("key", val)

	val2, err := cluster.Get("key2").Result()
	if err == redis.Nil {
		fmt.Println("key2 does not exist")
	} else if err != nil {
		fmt.Println(err)
	} else {
		fmt.Println("key2", val2)
	}
	// Output:
	// PONG <nil>
	// key value
	// key2 does not exist
}
