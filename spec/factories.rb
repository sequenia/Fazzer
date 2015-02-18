FactoryGirl.define do
  factory :device do
    user_id 0
    token "12345678"
    platform "android"
    enabled true
  end
end