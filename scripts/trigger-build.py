#!/usr/bin/env python
import argparse
import json
import logging
import requests
import sys
import os.path

log = logging.getLogger(__name__)
logging.getLogger("urllib3.connectionpool").setLevel(logging.ERROR)


class BaseError(Exception):
    pass


class UnknownRepoError(BaseError):
    pass


class UnauthorizedError(BaseError):
    pass


def get_latest_sha(owner, repo):
    """
    Get the latest SHA1 hash for a repo
    :param owner: owner of the repo
    :param repo: the repo
    :return: sha1 hash of latest commit
    """
    url = "https://api.github.com/repos/{owner}/{repo}/commits/HEAD".format(owner=owner, repo=repo)

    res = requests.get(url)

    if res.status_code == 200:
        data = res.json()
        return data["sha"]
    else:
        raise UnknownRepoError("could not find {owner}/{repo}".format(owner=owner, repo=repo))


def trigger_travis_build(owner, repo, token, use_pro=False, branch=None, message=None):
    request = {
        "request": {
            "branch": branch or "master",
            "message": message or "Remote build trigger"
        }
    }
    travis_api = "https://api.travis-ci.{0}".format("com" if use_pro else "org")
    url = "{travis}/repo/{owner}%2F{repo}/requests".format(travis=travis_api, owner=owner, repo=repo)
    res = requests.post(url,
                        data=json.dumps(request),
                        headers={
                            "Content-Type": "application/json",
                            "Accept": "application/json",
                            "Travis-API-Version": 3,
                            "Authorization": "token {0}".format(token)
                        })
    if "access denied" in res.text:
        raise UnauthorizedError("Travis token invalid")
    data = res.json()
    return data["@type"] != "error"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("gh_owner", help="The name owner of the GitHub repo")
    parser.add_argument("gh_repo", help="The GitHub repo name")
    parser.add_argument("tr_owner", help="The Travis repo name")
    parser.add_argument("tr_repo", help="The Travis repo name")
    parser.add_argument("--travis-token", help="The Travis-CI token", default=None)
    parser.add_argument("--travis-pro", help="Use Travis Pro", default=False, action="store_true")

    args = parser.parse_args()

    sha_file = "/var/lib/travis-trigger/{0}-{1}-{2}-{3}.sha".format(
        args.gh_owner, args.gh_repo, args.tr_owner, args.tr_repo
    )

    # get the latest GitHub commit SHA1
    latest_sha = get_latest_sha(args.gh_owner, args.gh_repo)
    log.info("Got latest SHA1 for {}/{}: {}".format(args.gh_owner, args.gh_repo, latest_sha))

    # compare it to the stored SHA1
    if os.path.exists(sha_file):
        previous_sha = open(sha_file, "r").read()
    else:
        previous_sha = None

    if previous_sha != latest_sha:
        with open(sha_file, "w") as fd:
            fd.write(latest_sha)
        # Trigger build if the SHA1 changes
        message = "Build triggered by change in {}/{}: {}".format(args.gh_owner, args.gh_repo, latest_sha)
        try:
            if trigger_travis_build(args.tr_owner, args.tr_repo, args.travis_token, message=message):
                log.info(message)
            else:
                log.error("Failed to trigger remote build!")
        except BaseError:
            log.exception("Failed to trigger remote build!")
    else:
        log.info("No change in SHA, build not triggered")

    return 0

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format='%(asctime)-15s %(message)s')
    sys.exit(main())

