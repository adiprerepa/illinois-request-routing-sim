FROM golang:1.19-alpine

WORKDIR /app

COPY go.* ./

RUN go mod download

COPY *.go ./

RUN go build -o /prime-main

EXPOSE 80

CMD [ "/prime-main" ]
