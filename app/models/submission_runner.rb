
class SubmissionRunner
    include SubmissionModule
    
    def run_server
        log "START: run server"
        c = get_compute
        s = create_server c
        id = s.instances[0].instance_id
        id
    end

    def get_and_wait_server_info instance_id
        log "START: get_and_wait server info"
        c = get_compute
        while true do
            break if server_enable? c, instance_id
        end
        get_info(get_server c, instance_id)
    end

    def shoutdown_server instance_id
        log "STOP: stop server"

        c = get_compute
        terminate_server c, instance_id
    end

    def deploy_target user, ip, submission, submission_dir
        # run clone
        log "START: clone"
        r = remote_exec user, ip, "/script/deploy_target.sh #{submission.repos_url} #{submission_dir}"
        puts r
    end

    def undeploy_target user, ip, submission, submission_dir
        log "STOP: docker"
        r = remote_exec user, ip, "/script/undeploy_target.sh #{submission_dir}"
        puts r
    end

    def test_target user, ip, submission, submission_dir
        work_dir = Dir.pwd
        problems = get_problems

        log "START: stress test"
        senario = problems[submission.problem] 
        r = remote_exec user, ip, "/script/test_target.sh #{senario} #{submission_dir}"

        if r.split(/\n/).last.strip == '0'
            # get report
            remote_cp user, ip, '/var/tmp/report.tar.gz', "#{work_dir}"
            sub_dir = "#{work_dir}/#{submission.id}"
            exec "mkdir -p #{sub_dir} && " +
            " tar xfz #{work_dir}/report.tar.gz -C #{sub_dir} && " + 
            " rm report.tar.gz"

            # get score
            score = 0
            open("#{sub_dir}/score.txt") do |f|
                score = f.read.to_i
            end
            
            # upload to s3
            files = Dir.glob("#{submission.id}/**/*")
               .find_all{|f| File::ftype(f) == "file"}
               .map{|x| x.sub(/.*#{submission.id}\//,"")}
            files.each{|x| puts x}

            files.each do |f|
                key = "results/#{submission.id}/#{f}"
                File.open("#{sub_dir}/#{f}") do |value|
                    puts "#{key} : #{value}"
                    upload_s3 key, value
                end
            end

            # clean up
            sleep(90)
            exec "rm -rf #{sub_dir}"

            # success
            submission.finished = true
            submission.status = 'COMPLETED'
            submission.score = score
            submission.save
        else
            p r

             # fail
            submission.finished = true
            submission.status = 'FAILED'
            submission.save
        end
    end

    def run submission
        submission.status = "RUNNING"
        submission.save

        begin
            # prepare 
            FileUtils.mkdir_p("submissions") unless FileTest.exist?("submissions")
            submission_dir = "submissions/#{submission.id}"

            # create server
            id = run_server
            r = get_and_wait_server_info id
            p r
            user = "ubuntu"
            ip = r[:public_ip_address]

            # deploy
            deploy_target user, ip, submission, submission_dir
            # test
            test_target user, ip, submission, submission_dir
            # stop
            undeploy_target user, ip, submission, submission_dir

        rescue => e
            # fail
            submission.finished = true
            submission.status = 'FAILED'
            submission.save

            raise e
        ensure
            # shoutdown
            shoutdown_server id
        end
    end

    def run_all
        Submission.all.
            where(finished: false).
            each do |x| 
                run x
            end
    end
end


