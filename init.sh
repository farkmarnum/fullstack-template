#!/usr/bin/env bash

set -e
trap cleanup SIGINT SIGTERM ERR

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v]

This script creates necessary AWS resources and set GitHub secrets accordingly

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR

  echo "Failure. Cleaning up..."
  # TODO
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m' BOLD="\033[1m"
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

show_init_warning() {
  msg "AWS Full-stack template initialization script
This utility will walk you through creating AWS resources and setting GitHub secrets.


❗️❗️❗️ ${RED}${BOLD}Warning${NOFORMAT} ❗️❗️❗️
Running this script will result in ${RED}${BOLD}charges on your AWS account${NOFORMAT}❗️

Estimated charges:
  Domain:  ${YELLOW}\$10-12 ${NOFORMAT}per year (depends on TLD)
  ELB:     ${YELLOW}\$16.20${NOFORMAT} per month, will increase with traffic
  ECS:     ${YELLOW}\$10.49${NOFORMAT} per month
  Route53: ${YELLOW}\$00.50${NOFORMAT} per month for hosted zone
  ECR:     ${YELLOW}<\$1${NOFORMAT} per month for container image storage
  S3:      ${YELLOW}~0${NOFORMAT} but increase with traffic
  CF:      ${YELLOW}~0${NOFORMAT} but increase with traffic

Total monthly charges (annual charges spread over 12 months) =
${YELLOW}~\$28/month${NOFORMAT}, but may increase with more traffic to your site

Note: some of these charges may be covered by AWS Free Tier if you are eligible.
"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  flag=0
  param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  return 0
}

parse_params "$@"
setup_colors

if ! command -v jq &> /dev/null
then
    echo "Error: jq must be installed"
    exit
fi

show_init_warning

while true; do
    read -p "$(echo -e $GREEN$BOLD\?$NOFORMAT) Would you like to proceed? [Yn]" resp
    case $resp in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) break;;
    esac
done

msg "


⚠️  Please have the following information ready:
    - A ${CYAN}${BOLD}domain name${NOFORMAT} that is available to register
    - A Google Analytics ${CYAN}${BOLD}tracking ID${NOFORMAT}
    - Your ${CYAN}${BOLD}contact information${NOFORMAT} (for domain registrar)
"

qp() {
  read -e -p "$(echo -e $GREEN$BOLD\?$NOFORMAT$BOLD $1: $NOFORMAT)" resp
  echo $resp
}

# constants:
AWS_REGION="us-east-1"
ContactType="PERSON"

# user input:
AWS_PROFILE=$(qp "AWS profile")
STACK_NAME=$(qp "Project name")
FRONTEND_DOMAIN=$(qp "Domain name")

GA_TRACKING_ID=$(qp "Google Analytics tracking ID")

msg "We'll need some contact information for the domain registrar. This information will not be public."
read -n 1 -s -r -p "(press any key to continue)"
echo ""

FirstName=$(qp "FirstName")
LastName=$(qp "LastName")

AddressLine1=$(qp "AddressLine1")
AddressLine2=$(qp "AddressLine2")
City=$(qp "City")
State=$(qp "State")
CountryCode=$(qp "CountryCode (e.g. US)")
ZipCode=$(qp "ZipCode")

Email=$(qp "Email")

CONTACT_INFO="FirstName=$FirstName,LastName=$LastName,ContactType=$ContactType,AddressLine1=string,AddressLine2=string,City=$City,State=$State,CountryCode=$CountryCode,ZipCode=$ZipCode,Email=$Email"

aws route53domains register-domain \
  --profile "$AWS_PROFILE" \
  --domain-name $FRONTEND_DOMAIN \
  --duration-in-years 1 \
  --auto-renew true \
  --admin-contact "$CONTACT_INFO" \
  --registrant-contact "$CONTACT_INFO" \
  --tech-contact "$CONTACT_INFO" \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact \
  --generate-cli-skeleton

# REGISTRAR_OPERATION_ID=$(aws route53domains register-domain \
  # --profile "$AWS_PROFILE" \
  # --domain-name $FRONTEND_DOMAIN \
  # --duration-in-years 1 \
  # --auto-renew true \
  # --admin-contact "$CONTACT_INFO" \
  # --registrant-contact "$CONTACT_INFO" \
  # --tech-contact "$CONTACT_INFO" \
  # --privacy-protect-admin-contact \
  # --privacy-protect-registrant-contact \
  # --privacy-protect-tech-contact \
#   | jq .OperationId)

# msg "\nWaiting for domain registration to complete. Note: this may take up to 15 minutes\n"

# while true; do
#     STATUS=$(get-operation-detail --operation-id $REGISTRAR_OPERATION_ID | jq .Status)
#     if [[ $STATUS == "SUCCESSFUL" ]]
#     then
#       echo "Success!"
#       break
#     else
#       printf "."
#       sleep 15
#     esac
# done

HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --profile "$AWS_PROFILE" \
  | jq --arg name "${FRONTEND_DOMAIN}." -r '.HostedZones | .[] | select(.Name=="\($name)") | .Id' \
  | sed 's/.*\///')

    # - CERTIFICATE_ARN

    # - CLOUDFORMATION_ROLE_ARN

    # - AWS_ACCESS_KEY_ID
    # - AWS_SECRET_ACCESS_KEY

