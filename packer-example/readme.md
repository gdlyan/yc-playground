# Packer Quickstart
This is a creative adaptation of the Packer example from the [Yandex Cloud Engineer Course](https://practicum.yandex.ru/ycloud/). Added the following items that were not covered in the lesson:
- running Packer in a Docker container
- keeping secrets and other sensitive things in variables
- installing Docker app running on port 3000
- trying out parallel building (multiple source sections in one configuration)
- fixing the `Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend)` on Ubuntu 18
    