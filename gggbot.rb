require 'eventmachine'

module Bot
    Nick = 'InspectorGadget'
    # just so I don't forget to remove the password when
    #+I'm uploading this file somewhere ...
    Password = IO.read('password')
    Ident = 'InspectorGadget'
    Realname = 'Dr. Dr. I. Gadget'
    Perform = '##off-archlinux'
    Admins = %w(ben_m brandeis)
    Blacklist = %w()

    def parse_msg(who, s)
        channel, message = s.scan(/(\S+) :(.+)/).first

        # admin only commands go here
        if Admins.include?(who)
            case message
            when '%quit'
                send_data "QUIT :Yes, my master!\r\n"
                sleep 2
                close_connection
            when /^%join (\S+)/
                send_data "JOIN #{$1}\r\n"
            end
        end

        # regular commands go here
        case message
        when '%version'
            echo channel, 'Version 0.awesome'
        when '%wishlist'
            echo channel, 'http://etherpad.com/bgQFCJRloy'
        when '%admins'
            echo channel, Admins * ', '
        end
    end

    def echo(channel, message)
        send_data "PRIVMSG #{channel} :#{message}\r\n"
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
            send_data "PONG #{rest}\r\n"
        when "PRIVMSG"
            parse_msg who, rest
        when "JOIN"
            unless Blacklist.include?(who)
                puts "MODE #{rest[1..-1]} +o #{who}"
                send_data "MODE #{rest[1..-1]} +o #{who}\r\n"
            end
        end
    end

    def post_init
        send_data "NICK #{Nick}\r\n"
        send_data "USER #{Ident} bla bla :#{Realname}\r\n"
        send_data "PRIVMSG NickServ :identify ben_m #{Password}\r\n"
        send_data "JOIN #{Perform}\r\n"
    end
end

EM.run do
    EM.connect 'irc.freenode.org', 6667, Bot
end
