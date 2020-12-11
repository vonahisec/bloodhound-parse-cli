#!/usr/bin/env ruby
#
# This script was made to simplify the parsing of bloodhound-python
# Author: Alton Johnson (@altonjx)
# Version 1.0
# Last Updated: November 30, 2020

require 'json'
require 'terminal-table'

computers_file = File.open("computers.json").read
users_file = File.open("users.json").read
domains_file = File.open("domains.json").read
groups_file = File.open("groups.json").read

computers = JSON.parse(computers_file)
users = JSON.parse(users_file)
domains = JSON.parse(domains_file)
groups = JSON.parse(groups_file)

# domain_users = {}
domain_groups = {}
domain_computers = {}
sessions = {}

sid_to_group = {}
sid_to_user = {}
sid_to_computer = {}

terminal_table_rows = []

# Define users
users["users"].each do |user|
    domain_user = user["Properties"]["name"].split("@")[0]
    user_sid = user["Properties"]["objectid"]

    unless sid_to_user[user_sid]
        sid_to_user[user_sid] = domain_user
    end

    # domain_users[user_sid] = domain_user
end

# Define groups and what members belong to them
# Establish groups
groups["groups"].each do |group|
    group_name = group["Properties"]["name"].split("@")
    group_sid = group["Properties"]["objectid"]

    unless sid_to_group[group_sid]
        sid_to_group[group_sid] = group_name
    end

    unless domain_groups[group_name]
        domain_groups[group_name] = {:members => {}}
    end

    if group["Members"]
        group["Members"].each do |member|
            if member["MemberType"] == "User"
                user_sid = member["MemberId"]
                username = sid_to_user[user_sid]

                # Add members to this group
                unless domain_groups[group_name][:members][username]
                    domain_groups[group_name][:members][username] = {:sessions => []}
                end
            end
        end
    end
end

# Add computers. Also add sessions to users
computers["computers"].each do |computer|
    computer_name = computer["Properties"]["name"]
    computer_sid = computer["Properties"]["objectid"]

    unless sid_to_computer[computer_sid]
        sid_to_computer[computer_sid] = computer_name
    end
end

computers["computers"].each do |computer|
    if computer["Sessions"]
        computer["Sessions"].each do |session|
            session_user_sid = session["UserId"]
            session_computer_sid = session["ComputerId"]

            user = sid_to_user[session_user_sid]
            cname = sid_to_computer[session_computer_sid]

            domain_groups.each do |key, value|
                members = value[:members]
                if members[user]
                    members[user][:sessions] << cname
                    key.each do |group|
                        terminal_table_rows << [group, user, cname]
                    end
                end
            end

            # unless sessions[domain_users[user_sid]]
            #     sessions[domain_users[user_sid]] = []
            # end
            # unless domain_computers[computer_sid]
            #     domain_computers[computer_sid] = {:sessions => []}
            # end

            # sessions[domain_users[user_sid]] << computer_name
            # domain_computers[computer_sid][:sessions] << domain_users[user_sid]
        end
    end
end

# STDOUT
table = Terminal::Table.new :headings => ["Group Name", "Domain User","Active Logged In Session"], :rows => terminal_table_rows.uniq

puts table