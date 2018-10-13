package main

import (
	"fmt"

	"github.com/go-redis/redis"
)

var client *redis.Client
var cluster *redis.ClusterClient
var sentinal *redis.SentinelClient

func init() {
	// client = redis.NewClient(&redis.Options{
	// 	Addr:     "redis:6379",
	// 	Password: "", // no password set
	// 	DB:       0,  // use default DB
	// })
	cluster = redis.NewClusterClient(&redis.ClusterOptions{
		Addrs: []string{"redis-0:6379", "redis-1:6379", "redis-2:6379", "redis-3:6379", "redis-4:6379", "redis-5:6379"},
	})
}

func main() {
	pong, err := cluster.Ping().Result()
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(pong)

	err = cluster.Set("test", "OK", 0).Err()
	if err != nil {
		fmt.Println(err)
	}

	val, err := cluster.Get("test").Result()
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println("test", val)
}
