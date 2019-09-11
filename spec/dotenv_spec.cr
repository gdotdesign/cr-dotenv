require "spec"
require "../src/dotenv"

Spec.before_each do
  ENV.clear
end

Dotenv.verbose = false

describe Dotenv do
  describe "#load_string" do
    it "loads environment variables with quoted values" do
      Dotenv.load_string %[VAR="Hello, World!"]
      ENV["VAR"].should eq "Hello, World!"
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

  describe "#load" do
    context "From file" do
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
