require 'json'

GATLING_HOME="/Users/koduki/Downloads/gatling-charts-highcharts-bundle-2.2.2"


problems = {1=>"IsuconBank"}
post = JSON.parse(open('post.json').read)

# run gatling
senario = problems[post['problem']] 
cmd = "#{GATLING_HOME}/bin/gatling.sh -s #{senario}"
stdout = `#{cmd}`
status = $?
