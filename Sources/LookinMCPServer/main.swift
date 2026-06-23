import Foundation
import LookinMCPCore

let args = Array(CommandLine.arguments.dropFirst())
let exitCode = await CLI.dispatch(args)
exit(exitCode)
