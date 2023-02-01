package main

import (
	"bytes"
	"crypto/rand"
	"fmt"
	"io"
	"io/ioutil"
	"math"
	"net/http"
	"os"
	"strconv"
	"time"
)

var (
	callSize       float64
	callDownstream string
)

func callMeHandler(w http.ResponseWriter, r *http.Request) {
	reqBodySize, _ := io.Copy(ioutil.Discard, r.Body)
	fmt.Printf("request of size %v recvd. ", reqBodySize)
	if callDownstream == "NONE" {
		fmt.Println()
		w.Write([]byte("done."))
		return
	}
	requestUrl := fmt.Sprintf("http://%s:9080/callme", callDownstream)
	body := make([]byte, int(math.Pow(10, 6)*callSize))
	_, err := rand.Read(body)
	if err != nil {
		fmt.Printf("couldn't read random bytes: %v", err)
		return
	}
	bodyReader := bytes.NewReader(body)
	req, err := http.NewRequest(http.MethodPost, requestUrl, bodyReader)
	if err != nil {
		fmt.Printf("couldn't create http request: %v", err)
		return
	}
	client := http.Client{
		Timeout: 30 * time.Second,
	}
	fmt.Printf("making call to %v size %v\n", callDownstream, callSize)
	_, err = client.Do(req)
	if err != nil {
		fmt.Printf("couldn't make request: %v", err)
		return
	}
}

func main() {
	callDownstream = os.Getenv("CALL_DOWNSTREAM")
	if callDownstream != "NONE" {
		callSize, _ = strconv.ParseFloat(os.Getenv("CALL_SIZE_MB"), 64)
	} else {
		callSize = 0
	}
	fmt.Printf("calling downstream service %v with size %v", callDownstream, callSize)
	mux := http.NewServeMux()
	mux.HandleFunc("/callme", callMeHandler)
	if err := http.ListenAndServe(":9080", mux); err != nil {
		fmt.Printf("couldn't start server: %v", err)
	}
}
