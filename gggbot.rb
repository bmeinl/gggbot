require 'eventmachine'

# STDERR = log

class Bot < EventMachine::Connection
    @@Nick = 'InspectorGadget'
    # just so I don't forget to remove the password when
    #+I'm uploading this file somewhere ...
    @@Password = IO.read('.password')
    @@Ident = 'InspectorGadget'
    @@Realname = 'Dr. Dr. I. Gadget'
    @@Perform = '##off-archlinux'
    @@admins = %w(ben_m brandeis)
    @@blacklist = []

    def initialize(*args)
        super
        send_data "NICK #{@@Nick}\r\n"
        send_data "USER #{@@Ident} bla bla :#{@@Realname}\r\n"
        send_data "PRIVMSG NickServ :identify ben_m #{@@Password}\r\n"
        send_data "JOIN #{@@Perform}\r\n"
    end

    def parse_msg(who, s)
        channel, message = s.scan(/(\S+) :(.+)/).first

        # admin only commands go here
        if @@admins.include?(who)
            case message
            when '%quit'
                EventMachine::stop_event_loop
            when /^%join (\S+)/
                send_data "JOIN #{$1}\r\n"
            when /^%part/
                send_data "PART #{channel}\r\n"
            when /^%add (\S+)/
                @@admins << $1
                echo channel, "Tada!"
            when /^%remove (\S+)/
                unless $1 == 'ben_m'
                    @@admins.delete $1
                    echo channel, "Tada!"
                end
            when /^%blacklist (\S+)/
                unless $1 == 'ben_m'
                    @@blacklist << $1
                end
            when /^%whitelist (\S+)/
                @@blacklist.delete $1
            end
        end

        # regular commands go here
        case message
        when '%version'
            echo channel, 'Version 0.awesome'
        when '%wishlist'
            echo channel, 'http://etherpad.com/bgQFCJRloy'
        when '%admins'
            echo channel, @@admins * ', '
        when '%source'
            echo channel, 'http://github.com/bmeinl/gggbot'
        when '%ping'
            echo channel, ['Donkey Kong.', 'Pongidong.', 'Woosh', 'I pooped :('][rand 4]
        when '%help'
            echo channel, 'This bot is pretty much useless at the moment.'
        when '%commands'
            echo channel, 'version, wishlist, admins, source, ping, help, commands'
            echo channel, 'admins only: quit, join, part, add, remove, blacklist, whitelist'
        end
    end

    def echo(channel, message)
        send_data "PRIVMSG #{channel} :#{message}\r\n"
    end

    def unbind
        send_data "QUIT :Yes, my master!\r\n"
    end

    def receive_data(data)
        $stderr.puts data
        # who: who sent the message
        # what: what type of message (PRIVMSG, PING, ...)
        # rest: rest of message, depends on 'what'
        who, what, rest = data.scan(/:([^!]+)\S+ (\S+) (.+)\r\n/).first

        # handle 'what' here
        case what
        when "PING"
            send_data "PONG #{rest[1..-1]}\r\n"
        when "PRIVMSG"
            parse_msg who, rest
        when "JOIN"
            unless @@blacklist.include?(who)
                puts "MODE #{rest[1..-1]} +o #{who}"
                send_data "MODE #{rest[1..-1]} +o #{who}\r\n"
            end
        end
    end
end

EventMachine::run do
    EventMachine::connect 'irc.freenode.org', 6667, Bot
end
