# Utility binaries usage guide

* [How to use `tf-reserve` ?](#howto_tf_reserve)
* [How to configure a test script to use Testflinger ?](#howto_configure_test_with_tf)

## <a name="howto_tf_reserve"></a>How to use `tf-reserve` ?

In order to manually connect to a Testflinger machine, you can use the `tf-reserve` script. Ideally, the `PATH` needs to be updated in your `.bashrc` file to contain the path to your `tf-reserve` script.

Here is how to use it:

* First, define your Launchpad username: `export LP_USER=<your_lp_username>`. You can also have it defined in you `.bashrc` in order to not type it each time you open a new console.
* Then, reserve your machine like: `tf-reserve [<queue_name>] [<distro_name | image_url>] [<boot_media>]`. The parameter `queue_name` is not mandatory but it is strongly advised to define it (e.g, `rockman` gives you a machine with GPUs, etc.). If not chosen, the machine will be the first one available in the TF pool. By default, `distro_name` will be `noble` but you can change it. Sometimes, instead of the distribution, you need to tell TF to boot with a custom `image_url`. This can be useful to reserve special kind of hardwares (like an NVIDIA ORIN board). Lastly, you sometimes need to tell TF from which media the machine needs to boot through the optional `boot_media` parameter (like an `usb` stick). Here is an example on how to reserve an NVIDIA ORIN board that needs the 3 parameters defined:

```
tf-reserve nvidia-jetson-agx-orin https://cdimage.ubuntu.com/nvidia-tegra/ubuntu-server/jammy/daily-preinstalled/current/jammy-preinstalled-server-arm64+tegra-igx.img.xz usb
```

Most of the time, when you need a normal machine, the following will suffice:
```
tf-reserve rockman
```

You can check the list of available TF queues at https://testflinger.canonical.com/queues

(Note: [here](https://docs.google.com/document/d/1YhwbyWNGz4K8k8zsKhMBqbII5NkuD70cxCfOs5aPOl0/edit) is how to configure an NVIDIA ORIN board after it has been reserved. These machines require extra configuration in order to work properly)

## <a name="howto_configure_test_with_tf"></a>How to configure a test script to use Testflinger ?

Similarly, to do what's described above programmatically in a test script under `/tests`, you can add the following at the beginning of you script:

```bash
# testflinger_queue: <queue_name>
# [ testflinger_img_url: <img_url> ]
# [ testflinger_boot_media: <boot_media> ]

# The rest of your script executes on the reserved TF machine.
```