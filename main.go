package main

import (
	"fmt"
	"math"
	"net/http"
	"strconv"
	"time"
)

func sumOfPrimes(w http.ResponseWriter, r *http.Request) {
	begin := 3
	end := 100000
	if r.URL.Query().Has("begin") {
		val, err := strconv.Atoi(r.URL.Query().Get("begin"))
		if err == nil {
			begin = val
		}
	}
	if r.URL.Query().Has("end") {
		val, err := strconv.Atoi(r.URL.Query().Get("end"))
		if err == nil {
			end = val
		}
	}
	start := time.Now().UnixMilli()
	fmt.Printf("calculating from %d to %d ", begin, end)
	sum := 0
	for begin <= end {
		prime := true
		for i := 2; i <= int(math.Sqrt(float64(begin))); i++ {
			if begin%i == 0 {
				prime = false
				break
			}
		}
		if prime {
			sum += begin
		}
		begin++
	}
	finish := time.Now().UnixMilli()
	fmt.Printf("took %d millis\n", finish-start)
	w.Write([]byte(strconv.Itoa(begin + end)))
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/primeRange", sumOfPrimes)
	if err := http.ListenAndServe(":8081", mux); err != nil {
		fmt.Printf("couldn't start server: %v", err)
	}
}
