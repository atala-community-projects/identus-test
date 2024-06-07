import { Command, Argument, Option } from 'commander'
import { execSync } from 'child_process'

const program = new Command()

program
  .name('identus-test')
  .description('CLI for identus-test suite setup')

program.command('query')
  .description('query the version of a particular component')
  .addArgument(
    new Argument('<component>', 'the component whose version to query')
      .choices(['cloud-agent', 'mediator'])
  )
  .addArgument(
    new Argument('[version]', 'the identus release')
      .default('2.12')
  )

  .addOption(
    new Option('-o, --owner <owner>', 'the github owner org to draw from')
      .default('input-output-hk')
  )
  .addOption(
    new Option('-r, --repo <repo>', 'the name of the github repo releases are stored in')
      .default('atala-releases')
  )
  .addOption(
    new Option('-v, --version <version>', 'the identus release number')
      .default('2.12')
  )
  .action((component, version, options) => {
    const result = execSync([
      './bin/query.sh',
      '--owner', options.owner,
      '--repo', options.repo,
      '--version', version,
      `--component "${component.replace('-', ' ')}"`
    ].join(' '))

    console.log(result.toString())
  })

program.parse()
