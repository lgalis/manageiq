require "spec_helper"

describe VmOrTemplateController do
  context "#snap_pressed" do
    before :each do
      set_user_privileges
      controller.stub(:role_allows).and_return(true)
      vm = FactoryGirl.create(:vm_vmware)
      @snapshot = FactoryGirl.create(:snapshot, :vm_or_template_id => vm.id,
                                                :name              => 'EvmSnapshot',
                                                :description       => "Some Description"
                                    )
      vm.snapshots = [@snapshot]
      tree_hash = {
        :trees       => {
          :vandt_tree => {
            :active_node => "v-#{vm.id}"
          }
        },
        :active_tree => :vandt_tree
      }

      session[:sandboxes] = {"vm_or_template" => tree_hash}
    end

    it "snapshot node exists in tree" do
      post :snap_pressed, :id => @snapshot.id
      expect(response).to render_template('vm_common/_snapshots_tree')
      expect(assigns(:flash_array)).to be_blank
    end

    it "when snapshot is selected center toolbars are replaced" do
      post :snap_pressed, :id => @snapshot.id
      expect(response).to render_template('vm_common/_snapshots_tree')
      expect(response.body).to include("center_tb")
      expect(assigns(:flash_array)).to be_blank
    end

    it "deleted node pressed in snapshot tree" do
      controller.should_receive(:build_snapshot_tree)
      post :snap_pressed, :id => "some_id"
      expect(response).to render_template('vm_common/_snapshots_tree')
      expect(assigns(:flash_array).first[:message]).to eq("Last selected Snapshot no longer exists")
      expect(assigns(:flash_array).first[:level]).to eq(:error)
    end
  end

  context "#show" do
    before :each do
      set_user_privileges
      EvmSpecHelper.seed_specific_product_features("dashboard_show", "vandt_accord", "vms_instances_filter_accord")
      @vm = FactoryGirl.create(:vm_vmware)
    end

    it "redirects user to explorer that they have access to" do
      controller.instance_variable_set(:@sb, {})
      get :show, :id => @vm.id
      expect(response).to redirect_to(:controller => "vm_infra", :action => 'explorer')
    end

    it "redirects user to Workloads explorer when user does not have access to Infra Explorer" do
      controller.instance_variable_set(:@sb, {})
      get :show, :params => {:id => @vm.id}
      expect(response).to redirect_to(:controller => "vm_or_template", :action => 'explorer')
    end

    it "redirects user back to the url they came from when user does not have access to any of VM Explorers" do
      User.any_instance.stub(:role_allows?).and_return(false)
      controller.instance_variable_set(:@sb, {})
      request.env["HTTP_REFERER"] = "http://localhost:3000/dashboard/show"
      get :show, :id => @vm.id
      expect(response).to redirect_to(:controller => "dashboard", :action => 'show')
      expect(assigns(:flash_array).first[:message]).to include("is not authorized to access")
    end
  end
end
