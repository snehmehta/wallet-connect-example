# Wallet_connect_example

## Purpose
The purpose of this app is act as a test bed showing sequeunce wallet connect deep link issue.

## Issue in detail
For native application to connect to sequeunce wallet is through deeplink, the deep link is created like 
`https://sequence.app/wc?uri=${uri}`, 

Here, the expected behavior is to take to sequeunce wallet and show connect option, 
but actually it only show logo of wallet connect and cancel option, 
native app user are unable to connect sequeunce wallet using deep link.

## Credential setting 
Inside of `main.dart` line number 45 and 56 replace `<project-id-here>` with wallet connect project Id, 
which can be found/ created from https://walletconnect.com/ dashboard.

