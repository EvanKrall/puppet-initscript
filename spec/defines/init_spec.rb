require 'spec_helper'

describe 'initscript' do
  let(:title) { "initscriptname" }
  let(:facts) {{
    :operatingsystem => 'Ubuntu',
    :lsbdistrelease => '14.04',
  }}

  context 'Should compile with just command argument and operatingsystem fact' do
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
      should contain_file('initscript initscriptname').with_path('/etc/init.d/initscriptname') \
        .with_content(%r{^DAEMON=foo}) \
        .with_content(%r{^NAME=initscriptname$}) \
        .with_content(%r{^DAEMON_ARGS=\( bar baz\\ \\<baz\\>\\ baz \)$}) \
    }
  end

  context 'properly escaped shellwords sysv_sles' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'sysv_sles',
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/etc/init.d/initscriptname') \
        .with_content(%r{^\s+startproc foo bar baz\\ \\<baz\\>\\ baz}) \
    }
  end

  context 'properly escaped shellwords systemd' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'systemd',
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/lib/systemd/system/initscriptname.service') \
        .with_content(%r{^ExecStart=foo bar baz\\ \\<baz\\>\\ baz}) \
    }
  end

  context 'properly escaped xml launchd' do
    let(:params) {{
      :command      => ['foo', 'bar', 'baz <baz> baz'],
      :init_style   => 'launchd',
      :launchd_name => "com.initscriptlaunchdname"
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/Library/LaunchDaemons/com.initscriptlaunchdname.daemon.plist') \
        .with_content(%r{<string>foo</string>\n\s*<string>bar</string>\n\s*<string>baz &lt;baz&gt; baz</string>}) \
    }
  end

  context 'properly escaped shellwords sysv_redhat' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'sysv_redhat',
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/etc/init.d/initscriptname') \
        .with_content(%r{^\s+foo bar baz\\ \\<baz\\>\\ baz}) \
    }
  end
  context 'sysv_redhat sources /etc/sysconfig/initscriptname' do
    let(:params) {{
      :command => ['foo', 'bar'],
      :init_style => 'sysv_redhat',
      :source_default_file => true,
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/etc/init.d/initscriptname') \
        .with_content(%r{\n\[ -e /etc/sysconfig/initscriptname \] && . /etc/sysconfig/initscriptname\n}) \
    }
  end


  context 'properly escaped shellwords upstart' do
    let(:params) {{
      :command    => ['foo', 'bar', 'baz <baz> baz'],
      :init_style => 'upstart',
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/etc/init/initscriptname.conf') \
        .with_content(%r{^script\n\s+exec foo bar baz\\ \\<baz\\>\\ baz\nend script\n}) \
    }
  end

  context 'upstart sources /etc/default/initscriptname' do
    let(:params) {{
      :command => ['foo', 'bar'],
      :init_style => 'upstart',
      :source_default_file => true,
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/etc/init/initscriptname.conf')
        .with_content(%r{^script\n\s+\[ -f /etc/default/initscriptname \] && . /etc/default/initscriptname\n\s+exec foo bar\nend script\n}) \
    }
  end

  context 'upstart omits description directive when description is empty' do
    let(:params) {{
      :command     => ['foo', 'bar', 'baz <baz> baz'],
      :init_style  => 'upstart',
      :description => '',
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/etc/init/initscriptname.conf') \
        .without_content(%r{^\s*description}) \
    }
  end

  context 'upstart forms pre-start script' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'upstart',
      :before_command => [['baz', 'qux'], ['spam', 'eggs']],
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_content(%r{^pre-start script\n  baz qux\n  spam eggs\nend script$})
    }
  end

  context 'systemd has ExecStartPre' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'systemd',
      :before_command => [['baz', 'qux'], ['spam', 'eggs']],
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_content(%r{^ExecStartPre=baz qux\nExecStartPre=spam eggs$})
    }
  end

  context 'upstart does not have pre-start script' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'upstart',
    }}
    it {
      should contain_file('initscript initscriptname') \
        .without_content("pre-start script")
    }
  end

  context 'sysv_debian forms pre-start script' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'sysv_debian',
      :before_command => [['baz', 'qux'], ['spam', 'eggs']],
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_content(%r{^    baz qux\n    spam eggs\n    start-stop-daemon })
    }
  end

  context 'upstart does ulimits' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'upstart',
      :ulimit         => { 'nofile'=> '1', 'rss'=>'2' },
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_content(%r{^limit nofile 1 1\nlimit rss 2 2$})
    }
  end

  context 'systemd does ulimits' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'systemd',
      :ulimit         => { 'nofile'=> '1', 'rss'=>'2' },
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_content(%r{^LimitNOFILE=1\nLimitRSS=2$})
    }
  end

  context 'sysv_debian does ulimits' do
    let(:params) {{
      :command        => ['foo', 'bar'],
      :init_style     => 'sysv_debian',
      :ulimit         => { 'nofile'=> '1', 'rss'=>'2' },
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_content(%r{^    ulimit -H -n 1\n    ulimit -S -n 1$})
        .with_content(%r{^    ulimit -H -m 2\n    ulimit -S -m 2$})
    }
  end

  context 'systemd sources /etc/default/initscriptname' do
    let(:params) {{
      :command => ['foo', 'bar'],
      :init_style => 'systemd',
      :source_default_file => true,
    }}
    it {
      should contain_file('initscript initscriptname') \
        .with_path('/lib/systemd/system/initscriptname.service')
        .with_content(%r{^ExecStart=sh -c \\\[\\ -f\\ /etc/default/initscriptname\\ \\\]\\ \\&\\&\\ .\\ /etc/default/initscriptname\\ \\;foo\\ bar}) \
    }
  end

end
