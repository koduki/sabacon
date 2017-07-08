module SubmissionsHelper
    def repos_link url, tag
        transd = url.sub(/\.git$/, '') + '/tree/' + tag
        link_to url, transd
    end

    def format_problem id
        p = Problem.find id
        "#{p.id}:#{p.name}"
    end
end
