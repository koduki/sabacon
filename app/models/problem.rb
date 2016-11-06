class Problem
    attr_reader :id, :name

    def initialize(id, name)
        @id = id
        @name = name
    end

    def self.all
        [Problem.new(1, 'いすこん銀行 - Easy')]
    end

    def self.find id
        self.all.find_all{|x| x.id == id}.first
    end
end