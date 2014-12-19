module Zendesk::Deployment
  class Committish
    include Comparable
    attr_reader :repo, :name, :ahead, :sha, :version

    def initialize(name, repo = '.')
      @repo = repo

      git_description = `cd #{repo} && git describe --tags --long --always #{name} 2>&- || true`.strip

      if !git_description.empty?
        @known = true
        @name, ahead, @sha = git_description.strip.split('-')
        @ahead = ahead.to_i
        @sha = @sha[1..-1] if @sha
        @sha ||= @name
      else
        @known = false
        @name = @sha = name
        @ahead = 0
      end

      @version = Gem::Version.new(name.sub(/^v/, "")) rescue nil
    end

    def ahead?
      ahead > 0
    end

    def valid_tag?
      !major.nil? && !ahead?
    end

    def to_s
      ahead? ? sha : name
    end

    def major
      version_segments[0]
    end

    def minor
      version_segments[1]
    end

    def describe
      if !@known
        "unknown commit #{sha}"
      elsif ahead?
        "#{sha} (#{ahead} commit(s) ahead of #{name})"
      else
        name
      end
    end

    def inspect
      "Committish: #{describe}"
    end

    def same_major?(other_tag)
      major == other_tag.major
    end

    def same_minor?(other_tag)
      same_major?(other_tag) && minor == other_tag.minor
    end

    def <=>(other_tag)
      if other_tag.is_a?(Committish)
        if version && other_tag.version
          version <=> other_tag.version
        else
          0
        end
      elsif other_tag.is_a?(String)
        self <=> new(other_tag)
      else
        raise "cant compare #{self.class.name} with #{other.class.name}"
      end
    end

    private

    def version_segments
      version ? version.segments : []
    end
  end
end
