"""
CLI entry point (Goal 9).
Commands: sync, rank, ticket <id>, simulate, export.
Debug mode: --debug prints full scoring inputs (Goal 6).
"""
import argparse


def main() -> None:
    parser = argparse.ArgumentParser(prog="ticket-agent", description="Ticket AI Agent")
    parser.add_argument("--debug", action="store_true", help="Print full scoring inputs")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("sync", help="Sync GitHub issues into local DB")
    subparsers.add_parser("rank", help="Rank open tickets with explanations")
    ticket_parser = subparsers.add_parser("ticket", help="Show ticket by id")
    ticket_parser.add_argument("id", type=str, help="Ticket/issue id")
    subparsers.add_parser("simulate", help="Simulate impact of weight changes")
    subparsers.add_parser("export", help="Export ranked backlog")

    args = parser.parse_args()
    # TODO: load config, dispatch to ingestion/scoring/bounty/tracking/scheduler/observability
    print(f"Command: {args.command} (debug={getattr(args, 'debug', False)})")


if __name__ == "__main__":
    main()
