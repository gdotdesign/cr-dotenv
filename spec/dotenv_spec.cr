require "spec"
require "../src/dotenv"

Spec.before_each do
  ENV.clear
end

describe Dotenv do
  describe "#load_string" do
    describe "simple quoted value" do
      it "reads with whitespaces" do
        hash = Dotenv.load_string "VAR=' value '"
        hash["VAR"].should eq " value "
      end

      it "reads one with double quotes" do
        hash = Dotenv.load_string %(VAR='"value"')
        hash["VAR"].should eq %("value")
      end

      it "reads one including simple quotes" do
        hash = Dotenv.load_string "VAR='va'lue'"
        hash["VAR"].should eq "va'lue"
      end
    end

    describe "double quoted value" do
      it "reads with whitespaces" do
        hash = Dotenv.load_string %(VAR=" value ")
        hash["VAR"].should eq %( value )
      end

      it "reads one with simple quotes" do
        hash = Dotenv.load_string %(VAR="'value'")
        hash["VAR"].should eq %('value')
      end

      it "reads one including double quotes" do
        hash = Dotenv.load_string %(VAR="va"l"ue")
        hash["VAR"].should eq %(va"l"ue)
      end
    end

    it "raises on space in an unquoted value" do
      ex = expect_raises(Dotenv::ParseError) do
        Dotenv.load_string "VAR=va lue"
      end
      ex.to_s.should eq "Parse error on line: `VAR=va lue`"
      ex.cause.to_s.should eq "An unquoted value cannot contain a whitespace: ' '"
    end

    it "raises on space before a variable value" do
      ex = expect_raises(Dotenv::ParseError) do
        Dotenv.load_string "VAR= val"
      end
      ex.to_s.should eq "Parse error on line: `VAR= val`"
      ex.cause.to_s.should eq "A value cannot start with a whitespace: ' '"
    end

    it "raises on '#' inside a variable key" do
      ex = expect_raises(Dotenv::ParseError) do
        Dotenv.load_string "V#AR=val"
      end
      ex.to_s.should eq "Parse error on line: `V#AR=val`"
      ex.cause.to_s.should eq "A variable key cannot contain a '#'"
    end

    it "strips whitespaces" do
      Dotenv.load_string "  VAR=Hello \t\r "
      ENV["VAR"].should eq "Hello"
    end

    it "does not override existing var" do
      ENV["VAR"] = "existing"
      Dotenv.load_string "VAR=Hello"
      ENV["VAR"].should eq "existing"
    end

    it "ignores commented lines" do
      hash = Dotenv.load_string <<-DOTENV
      # This is a comment
      VAR=Dude
      DOTENV
      hash.should eq({"VAR" => "Dude"})
    end

    it "ingores empty lines" do
      hash = Dotenv.load_string <<-DOTENV

      VAR=Dude

      DOTENV
      hash.should eq({"VAR" => "Dude"})
    end

    it "reads allowed `=` in values" do
      hash = Dotenv.load_string "VAR=postgres://foo@localhost:5432/bar?max_pool_size=10"
      hash.should eq({"VAR" => "postgres://foo@localhost:5432/bar?max_pool_size=10"})
    end

    it "reads valid lines only" do
      Dotenv.load_string "VAR1=Hello\nHELLO:asd"
      ENV["VAR1"].should eq "Hello"
      ENV["HELLO"]?.should be_nil
    end
  end

  describe "#load?" do
    it "returns nil on missing file" do
      Dotenv.load?(".some-non-existent-env-file").should be_nil
    end

    it "loads environment variables" do
      tempfile = File.tempfile "dotenv", &.print("VAR=Hello")
      begin
        Dotenv.load? tempfile.path
        ENV["VAR"].should eq "Hello"
      ensure
        tempfile.delete
      end
    end
  end

  describe "#load" do
    context "From file" do
      it "raises on missing file" do
        expect_raises(Errno) do
          Dotenv.load ".some-non-existent-env-file"
        end
      end

      it "loads environment variables" do
        tempfile = File.tempfile "dotenv", &.print("VAR=Hello")
        begin
          Dotenv.load tempfile.path
          ENV["VAR"].should eq "Hello"
        ensure
          tempfile.delete
        end
      end
    end

    context "From IO" do
      it "loads environment variables" do
        io = IO::Memory.new "VAR2=test\nVAR3=other"
        hash = Dotenv.load io
        hash["VAR2"].should eq "test"
        hash["VAR3"].should eq "other"
        ENV["VAR2"].should eq "test"
        ENV["VAR3"].should eq "other"
      end
    end

    context "From Hash" do
      it "loads environment variables" do
        hash = Dotenv.load({"test" => "test"})
        hash["test"].should eq "test"
        ENV["test"].should eq "test"
      end
    end
  end
end
