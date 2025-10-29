terraform {
  required_providers {
    criblio = {
      source  = "criblio/criblio"
    }
  }
}

provider "criblio" {
  # Credentials will be read from environment variables
}