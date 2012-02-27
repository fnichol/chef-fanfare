require 'chefspec'

describe 'fanfare::applications' do
  let (:chef_run) { ChefSpec::ChefRunner.new.converge 'fanfare::applications' }
  it 'should do something' do
    pending 'Your recipe examples go here.'
  end
end
