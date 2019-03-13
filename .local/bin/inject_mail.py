#!/usr/bin/python3
"""Inject email directly into maildir."""
import mailbox
import email
import argparse
import os
from email.mime.message import MIMEMessage
import email.utils


def main():
    """Program entry."""
    parser = argparse.ArgumentParser()
    parser.add_argument("--address", type=str)
    parser.add_argument("--maildir", type=str)
    parser.add_argument("--subject", type=str)
    parser.add_argument("--input", type=str)
    args = parser.parse_args()
    if not args.address or not args.subject:
        print("address and subject required")
        return
    with open(args.input, 'r') as f:
        message = mailbox.email.message_from_file(f)
    if not args.maildir or not os.path.exists(args.maildir):
        print("maildir does not exist")
        return
    print(message)
    maildir = mailbox.Maildir(args.maildir)
    msg = MIMEMessage(message)
    msg.add_header("To", args.address)
    msg.add_header("From", args.address)
    msg.add_header("Subject", args.subject)
    msg.add_header("Date", email.utils.formatdate(localtime=True))
    maildir.add(msg)


if __name__ == "__main__":
    main()
