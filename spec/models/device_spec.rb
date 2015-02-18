require 'spec_helper'

describe Device do
  let(:device) { FactoryGirl.build(:device) }

  subject { device }

  it { should respond_to(:id) }

  it { should be_valid }
end
