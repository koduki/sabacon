module SubmissionModule
    def log msg
        puts msg
    end

    def exec cmd
        log "EXEC: " + cmd
        stdout = `#{cmd}`
        status = $?
        {stdout:stdout, status:status}
    end

    def remote_exec user, ip, cmd
        server = ip
        user = user
        port = 22

        log "REMOTE_EXEC: #{user}@#{server}:#{port} $ " + cmd
        opt = {
            :keys => '/root/.ssh/id_rsa',
            :port => port
        }
        Net::SSH.start(server, user, opt) do |ssh|
            ssh.exec!(cmd)
        end
    end

    def remote_cp user, ip, src, dst
        server = ip
        user = user
        port = 22

        log "REMOTE_COPY: #{user}@#{server}:#{port}:#{src} #{dst}" 
        opt = {
            :keys => '/root/.ssh/id_rsa',
            :port => port
        }
        Net::SSH.start(server, user, opt) do |ssh|
            ssh.scp.download! src, dst
        end
    end

    def get_problems
        {1 => "IsuconBank"}
    end

    def wait
        limit = 3
        print "wait #{limit} seconds, "
        (1..limit).each do |n|
            print "#{n} "
            sleep(1)
        end
        puts
    end

    #
    # aws api
    #

    def get_compute
        access_key = ENV['AWS_ACCESS_KEY']
        secret_key = ENV['AWS_SECRET_KEY']
        region = "ap-northeast-1"

        Aws::EC2::Client.new(
            credentials: Aws::Credentials.new(access_key , secret_key),
            region: region
        )
    end

    def create_server compute
        compute.run_instances(
            image_id:'ami-76c21c17', 
            min_count:1, 
            max_count:1, 
            instance_type:'t2.micro', 
            key_name:'sabacon',
            security_group_ids:['launch-wizard-1']
        )
    end

    def terminate_server compute, instance_id
        compute.terminate_instances(:instance_ids => [instance_id])
    end

    def get_server compute, instance_id
        server = compute.describe_instances(instance_ids: [instance_id])
    end

    def get_info server
        s = server[0][0].instances[0]
        {
            instance_id:s.instance_id,
            image_id:s.image_id,
            fqdn:s.public_dns_name,
            public_ip_address:s.public_ip_address,
            private_ip_address:s.private_ip_address,
            state:s.state.name
        }
    end

    def server_enable? compute, instance_id
        compute.describe_instance_status(instance_ids:[instance_id]).
        instance_statuses.
        map{|s| s.system_status.status == 'ok'}[0]
    end

    def upload_s3 key, value
        access_key = ENV['AWS_ACCESS_KEY']
        secret_key = ENV['AWS_SECRET_KEY']
        region = "ap-northeast-1"

        client = Aws::S3::Client.new(
            :region => region,
            :access_key_id => access_key,
            :secret_access_key => secret_key,
        )

        client.put_object(
            :bucket => 'sabacon', 
            :acl => 'public-read',
            :key    => key, 
            :body   => value)
    end
end


