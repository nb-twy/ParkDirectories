#!/usr/bin/python

import argparse

def add_bookmark(args):
    if args.name:
        print(f"Park the current directory referenced by {args.name}")
    else:
        print("ERROR -- Name Required")

def delete_bookmark(args):
    if args.name:
        print(f"Delete parked directory referenced by {args.name}")
    else:
        print("ERROR -- Name Required")

def list_bookmarks(args):
    print("Show list of parked directories")

def clear_bookmarks(args):
    print("Clear the list of parked directories")

def cd_bookmark(args):
    if args.name:
        print(f"Change to directory referenced by {args.name}")
    else:
        print("ERROR -- Name Required")


if __name__ == "__main__":
    argparser = argparse.ArgumentParser(description = "Park Directories:  Park (bookmark) directories, switch quickly from anywhere to parked directories, and manage the list")
    argparser.add_argument("name", nargs="?", help = "Name of bookmarked directory")
    argparser.add_argument("-a", "--add", dest = "action", action = "store_const", const = "add", help = "Add a bookmarked directory")
    argparser.add_argument("-d", "--delete", dest = "action", action = "store_const", const = "delete", help = "Delete a bookmarked directory")
    argparser.add_argument("-l", "--list", dest = "action", action = "store_const", const = "list", help = "List all of the bookmarked directories")
    argparser.add_argument("-c", "--clear", dest = "action", action = "store_const", const = "clear", help = "Clear the list of bookmarked directories")
    args = argparser.parse_args()

    action = "cd"
    if args.action:
        action = args.action

    switcher = {
        "add": add_bookmark,
        "delete": delete_bookmark,
        "list": list_bookmarks,
        "clear": clear_bookmarks,
        "cd": cd_bookmark
    }

    func = switcher.get(action, lambda: "Invalid action")
    func(args)

