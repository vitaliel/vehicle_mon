# Makefile for the project

start-db:
	sudo pg_ctlcluster 12 main start

stop-db:
	sudo pg_ctlcluster 12 main stop
