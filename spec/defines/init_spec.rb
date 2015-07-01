require 'spec_helper'

describe 'initscript' do
  let(:title) { "initscriptname" }
  let(:launchd_name) { "com.initscriptlaunchdname" }
  
  context 'Should compile with just command argument and operatingsystem fact' do
    let(:facts) {{
      :operatingsystem => 'Ubuntu',
    }}
    let(:params) {{
      :command => ['hi', 'hello'],
    }}
    it { should compile }
  end

  context 'properly escaped shellwords sysv_debian' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'sysv_debian',
    }}
    it {
      should contain_file('/etc/init.d/initscriptname') \
        .with_content(%r{^DAEMON=foo}) \
        .with_content(%r{^NAME=initscriptname$}) \
        .with_content(%r{^DAEMON_ARGS=\( bar baz\\ \\<baz\\>\\ baz \)$}) \
        .with_content(%r{^USER=root$}) \
        .with_content(%r{^GROUP=root$}) \
    }
  end

  context 'properly escaped shellwords sysv_sles' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'sysv_sles',
    }}
    it { should contain_file('/etc/init.d/initscriptname').with_content(%r{^\s+foo bar "baz <baz> baz"})}
  end

  context 'properly escaped shellwords systemd' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'systemd',
    }}
    it { should contain_file('/etc/init.d/initscriptname').with_content(%r{^\s+foo bar "baz <baz> baz"})}
  end

  context 'properly escaped xml launchd' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'launchd',
    }}
    it {
      should contain_file('/Library/LaunchDaemons/com.initscriptlaunchdname.daemon.plist') \
        .with_content(%r{<string>foo</string>\n\s*<string>bar</string>\n\s*<string>baz &lt;baz&gt; baz</string>})
    }
  end

  context 'properly escaped shellwords sysv_redhat' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'sysv_redhat',
    }}
    it { should contain_file('/etc/init.d/initscriptname').with_content(%r{^\s+foo bar "baz <baz> baz"})}
  end

  context 'properly escaped shellwords upstart' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz baz baz'],
      :init_style => 'upstart',
    }}
    it { should contain_file('/etc/init.d/initscriptname').with_content(%r{^\s+foo bar "baz <baz> baz"})}
  end
end
