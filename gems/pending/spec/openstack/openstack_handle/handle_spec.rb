require "spec_helper"
require 'openstack/openstack_handle/handle'
require 'fog/openstack'

describe OpenstackHandle::Handle do
  before do
    @original_log = $fog_log
    $fog_log = double.as_null_object
  end

  after do
    $fog_log = @original_log
  end

  context "errors from services" do
    before do
      @openstack_svc = double('network_service')
      @openstack_project = double('project')

      @handle = OpenstackHandle::Handle.new("dummy", "dummy", "dummy")
      @handle.stub(:service_for_each_accessible_tenant).and_yield(@openstack_svc, @openstack_project)
    end

    it "ignores 404 errors from services" do
      expect(@openstack_svc).to receive(:security_groups).and_raise(Fog::Network::OpenStack::NotFound)

      data = @handle.accessor_for_accessible_tenants("Network", :security_groups, :id)
      data.should be_empty
    end

    it "ignores 404 errors from services returning arrays" do
      security_groups = double("security_groups").as_null_object
      expect(security_groups).to receive(:to_a).and_raise(Fog::Network::OpenStack::NotFound)

      expect(@openstack_svc).to receive(:security_groups).and_return(security_groups)

      data = @handle.accessor_for_accessible_tenants("Network", :security_groups, :id)
      data.should be_empty
    end
  end

  context "supports ssl" do
    it "handles non-ssl connections just fine" do
      fog      = double('fog')
      handle   = OpenstackHandle::Handle.new("dummy", "dummy", "address")
      auth_url = OpenstackHandle::Handle.auth_url("address", 5000, "https")

      OpenstackHandle::Handle.should_receive(:raw_connect).once do |_, _, address|
        address.should == auth_url
        fog
      end
      handle.connect(:tenant_name => "admin").should == fog
    end

    it "handles ssl connections just fine, too" do
      fog            = double('fog')
      handle         = OpenstackHandle::Handle.new("dummy", "dummy", "address", 5000, 'v2', 'ssl')
      auth_url_ssl   = OpenstackHandle::Handle.auth_url("address", 5000, "https")

      expect(OpenstackHandle::Handle).to receive(:raw_connect) do |_, _, address|
        expect(address).to eq(auth_url_ssl)
        fog
      end

      handle.connect(:tenant_name => "admin").should == fog
    end
  end
end
