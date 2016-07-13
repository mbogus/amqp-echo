// Copyright (c) 2016, M Bogus.
// This source file is part of the AMQP-ECHO open source project
// Licensed under Apache License v2.0
// See LICENSE file for license information

package main

import (
	"flag"
	"log"
	"time"

	"github.com/streadway/amqp"
)

var (
	uriParam       string
	queueNameParam string
	delayParam     int
)

func init() {
	flag.StringVar(&uriParam, "uri", "", "RabbitMQ broker URI")
	flag.StringVar(&queueNameParam, "queue", "", "RabbitMQ queue")
	flag.IntVar(&delayParam, "delay", 30, "delay in consuming of messages")
}

func main() {
	flag.Parse()
	forever := make(chan struct{})
	for {
		select {
		case <-forever:
			return
		case <-time.After(time.Duration(delayParam) * time.Second):
			err := listen(uriParam, queueNameParam)
			if err != nil {
				log.Print(err)
			}
		}
	}
}

func listen(uri string, queue string) error {

	connErr := make(chan *amqp.Error)
	forever := make(chan struct{})

	var err error

	go func() {
		e := <-connErr
		err = e
		close(forever)
	}()

	conn, err := amqp.Dial(uri)
	if err != nil {
		return err
	}
	defer conn.Close()

	conn.NotifyClose(connErr)

	ch, err := conn.Channel()
	if err != nil {
		return err
	}
	defer ch.Close()

	q, err := ch.QueueDeclare(
		queue, // name
		true,  // durable
		false, // delete when unused
		false, // exclusive
		false, // no-wait
		nil,   // arguments
	)

	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		false,  // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	if err != nil {
		return err
	}

	go func() {
		for d := range msgs {
			log.Printf("Received a message: '%s'", d.Body)

			if d.ReplyTo != "" {
				if e := ch.Publish(
					"",        // exchange
					d.ReplyTo, // routing key
					false,     // mandatory
					false,     // immediate
					amqp.Publishing{
						ContentType: d.ContentType,
						Body:        d.Body,
					}); err != nil {
					err = e
				}
			}

			d.Ack(false)
			conn.Close()
			return
		}
	}()

	log.Printf(" [*] Waiting for messages on '%s'.", q.Name)
	<-forever
	log.Printf(" [*] Exiting waiting.")
	return err
}
