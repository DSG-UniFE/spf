#!/usr/bin/python

from __future__ import division
import acoustid
import sys
import binascii 

def compare(bin1,bin2):
	#Calculate the number of different bits between strings
	assert len(bin1) == len(bin2)
	return sum(c1 != c2 for c1, c2 in zip(bin1, bin2))

def song_identification(song):
	
	res = acoustid.fingerprint_file(song)
	d = res[0]
	fp = res[1]
	return acoustid.lookup("HSzCnqXmrz",fp,d)
	
	
def song_compare(s1,s2):
	#Get duration and fingerprint from each song
	song_1 = acoustid.fingerprint_file(s1)
	song_2 = acoustid.fingerprint_file(s2)
	
	#durations
	d1 = song_1[0]
	d2 = song_2[0]
	
	#fingerprints (strings)
	f1 = song_1[1]
	f2 = song_2[1]
	
	#search some similarity in AcoustID cloud Database
	# HSzCnqXmrz is the key of my application registered (free) on AcoustID website
	
	result_1 = acoustid.lookup("HSzCnqXmrz",f1,d1)
	result_2 = acoustid.lookup("HSzCnqXmrz",f2,d2)
	
	
	#Get binary string from fingerprints
	bin_1 =  bin(int(binascii.hexlify(f1),16))
	bin_2 =  bin(int(binascii.hexlify(f2),16))
	print "\n\n"
	
	#Cut the longer fingerprint to equal the sorter, for comparing between eachother
	length = min(len(bin_1),len(bin_2))
	bin_1 = bin_1[:length]
	bin_2 = bin_2[:length]
	
	r = compare(bin_1, bin_2)/length*100
	print "Percentage of difference :"+ str(r) + "%"
	return r



