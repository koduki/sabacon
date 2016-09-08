
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
        if r.strip == '0'
            # get report
            remote_cp user, ip, '/var/tmp/report.tar.gz', "#{work_dir}"
            exec "mkdir -p ./public/reports/#{submission.id}/details && " +
            " tar xfz #{work_dir}/report.tar.gz -C ./public/reports/#{submission.id}/details && " + 
            " rm report.tar.gz"
            remote_cp user, ip, "/var/tmp/#{submission_dir}/result.txt", "./public/reports/#{submission.id}/details/"

            # success
            submission.finished = true
            submission.status = 'COMPLETED'
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


