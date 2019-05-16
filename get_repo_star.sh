#!/bin/bash
USER=$1
REPO=$2
AUTH=$3
HEADER="Accept: application/vnd.github.v3.star+json"
ORG_INFO="{name:.name,full_name:.full_name,owner:{login:.owner.login,html_url:.owner.html_url},html_url:.html_url,description:.description,created_at:.created_at,updated_at:.updated_at,pushed_at:.pushed_at,git_url:.git_url,ssh_url:.ssh_url,homepage:.homepage,stargazers_count:.stargazers_count,watchers_count:.watchers_count,forks_count:.forks_count,open_issues:.open_issues,default_branch:.default_branch,network_count:.network_count,subscribers_count:.subscribers_count}"
USER_INFO="{login:.login,id:.id,company:.company,location:.location,email:.email,name:.name,avatar_url:.avatar_url,gravatar_id:.gravatar_id,url:.url,type:.type,blog:.blog,hireable:.hireable,bio:.bio,created_at:.created_at,updated_at:.updated_at}"

if [  -z "$USER" -o -z "$REPO" -o -z "$AUTH" ]; then
  echo '[error] missing $1 : Github username'
  echo '[error] missing $2: Github repository name (only public repo)'
  echo '[error] missing $3 : Your github auth(username:password)'
  exit 1
fi

FILENAME=star_${USER}_${REPO}
rm -rf ${FILENAME}_*
curl -s -u ${AUTH} https://api.github.com/repos/$USER/$REPO | jq $ORG_INFO > ./temp/${FILENAME}_repo.json

stargazers_url=`curl -s -u ${AUTH}  https://api.github.com/repos/$USER/$REPO | jq .stargazers_url | sed 's/\"//g'`

star_cnt=`curl -s -u ${AUTH} https://api.github.com/repos/$USER/$REPO | jq .stargazers_count`
per_page=100
page_cnt=$((($star_cnt / $per_page) + 1))
i=1
count=0
while [ $i -le ${page_cnt} ]; do
    usernames=`curl -s -u ${AUTH} "${stargazers_url}?page=${i}&per_page=${per_page}" -H "${HEADER}" | jq '.[].user.login' | sed 's/\"//g'`
    echo $usernames
    for username in ${usernames[@]};
    do
    {
        curl -s -u "${AUTH}" "https://api.github.com/users/${username}" -H "${HEADER}" | jq $USER_INFO >> ./temp/${FILENAME}_users.json
    }
    done
    echo "Load users ..."

    i=$(($i + 1))
done

jq --slurpfile users ${FILENAME}_users.json '.users += $users' ./temp/${FILENAME}_repo.json > ${FILENAME}.json
jq -r '.users | (map(keys_unsorted) | .[0]) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv' ${FILENAME}.json > ${FILENAME}.csv