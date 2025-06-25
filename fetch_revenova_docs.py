import os
import requests
from urllib.parse import urlparse

# List of Revenova documentation URLs
URLS = [
    "https://documents.revenova.com/docs/revenova-tms-release-notes",
    "https://documents.revenova.com/docs/revenova-tms-installation-guide",
    "https://documents.revenova.com/docs/data-dictionary",
    "https://documents.revenova.com/docs/revenova-tms-web-services-guide",
    "https://documents.revenova.com/docs/integrations",
    "http://documents.revenova.com/docs/field-set-summary",
    "https://documents.revenova.com/docs/lightning-web-components-lwcs",
    "https://documents.revenova.com/docs/fleet-management-2",
    "https://documents.revenova.com/docs/accounting-seed-1",
    "https://documents.revenova.com/docs/payiq",
    "https://documents.revenova.com/docs/revenova-tms-analytics-user-guide",
]

BASE_DIR = os.path.join("docs", "Revenova Docs")


def fetch_and_save(url: str):
    """Fetch a single URL and save its content under docs/Revenova Docs."""
    parsed = urlparse(url)
    # Use last segment of path as folder name, stripping any trailing slashes
    segment = parsed.path.rstrip('/').split('/')[-1]
    if not segment:
        raise ValueError(f"Cannot determine folder name from URL: {url}")

    folder_path = os.path.join(BASE_DIR, segment)
    os.makedirs(folder_path, exist_ok=True)

    # Determine output file extension
    ext = ".pdf" if parsed.path.lower().endswith(".pdf") else ".html"
    filename = os.path.join(folder_path, f"index{ext}")

    print(f"Fetching {url} -> {filename}")
    response = requests.get(url, timeout=30)
    response.raise_for_status()

    # Write the content to file in binary mode
    with open(filename, "wb") as f:
        f.write(response.content)


def write_external_links():
    """Write external developer portal links to EXTERNAL_LINKS.md."""
    links = [
        "- **Salesforce Developer Documentation**  \n  https://help.salesforce.com/s/products/platform?language=en_US",
        "- **Estes Express API Developer Portal**  \n  https://developer.estes-express.com/",
        "- **ABF Freight (ArcBest) Shipping APIs**  \n  https://arcb.com/technology/shippers/API",
        "- **Ward Transport & Logistics API**  \n  https://wardtlctools.com/wardtrucking/apirequest/create",
        "- **A Duie Pyle Web Services**  \n  https://aduiepyle.com/resources/it-support/",
        "- **Saia Motor Freight Line Developer Portal**  \n  https://saiaprodapi.developer.azure-api.net/",
        "- **Southeastern Freight Lines Web Connect API**  \n  https://www.sefl.com/seflWebsite/technology/webConnect.jsp",
    ]

    path = os.path.join(BASE_DIR, "EXTERNAL_LINKS.md")
    os.makedirs(BASE_DIR, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(links))


def main():
    for url in URLS:
        fetch_and_save(url)
    write_external_links()


if __name__ == "__main__":
    main()
