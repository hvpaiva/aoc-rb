# frozen_string_literal: true

module RunnerTestSupport
  # Mimics Net::HTTP. `start` yields a FakeClient (or a static response when
  # no block-yielded request is needed). Captures host/port/options for
  # assertion; tests can inspect `captured` after.
  class FakeHTTP
    attr_reader :captured

    def initialize(response: nil, error: nil, captured: {})
      @response = response
      @error = error
      @captured = captured
    end

    def start(host, port, **opts, &block)
      @captured[:host] = host
      @captured[:port] = port
      @captured[:opts] = opts

      raise @error if @error

      if block
        yield(FakeHTTPClient.new(@response, @captured))
      else
        @response
      end
    end
  end

  # Used inside FakeHTTP.start { ... }; records the request and returns the
  # canned response.
  class FakeHTTPClient
    def initialize(response, captured)
      @response = response
      @captured = captured
    end

    def request(req)
      @captured[:request] = req
      @response
    end
  end

  # Stand-in for AOC::InputStore. Returns the canned input string.
  class FakeInputStore
    def initialize(value)
      @value = value
    end

    def read(_year, _day)
      @value
    end
  end

  # Stand-in for AOC::Paths used by Runner. Returns the configured year/day
  # for any path passed to `infer_year_day`, and a fixed variant slug (nil by
  # default, i.e. canonical) from `infer_variant`.
  class FakePaths
    def initialize(year:, day:, variant: nil)
      @year = year
      @day = day
      @variant = variant
    end

    def infer_year_day(_path)
      [@year, @day]
    end

    def infer_variant(_path)
      @variant
    end
  end

  # Captures sleep durations without actually sleeping.
  class FakeSleeper
    attr_reader :sleeps

    def initialize
      @sleeps = []
    end

    def sleep(seconds)
      @sleeps << seconds
    end
  end
end
