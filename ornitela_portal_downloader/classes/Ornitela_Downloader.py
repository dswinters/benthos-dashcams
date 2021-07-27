#!/usr/bin/env python
"""Download data from Ornitela's portal"""

from datetime import datetime
import os
import subprocess
import requests


def wccount(filename):
    out = subprocess.Popen(['wc', '-l', filename],
                           stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT
                           ).communicate()[0]
    return int(out.partition(b' ')[0])


class Ornitela_Downloader:

    def __init__(self, config):
        self.url = 'https://www.glosendas.net/cpanel/post.php'
        self.config = config
        self.tags = config['tags']

        # Log in to portal
        self.s = requests.Session()
        response = self.s.post(self.url, data={'username': config['username'],
                                               'password': config['password'],
                                               'login': 'Login'})
        if response.status_code == 200:
            print('Login success')

    def gen_request(self, serial, from_time, to_time, dtype):
        request = {"dnlselpm": '500p',
                   "dnlfromdt": from_time.strftime("%Y-%m-%d %H:%M"),
                   "dnltodt": to_time.strftime("%Y-%m-%d %H:%M"),
                   "dnlselkk": '1',
                   "dnlselcc": "{}".format(dtype),
                   self.config['tags'][serial]: ''}
        return request

    def download_month(self, serial, year, month):

        # Generate requests
        from_time = datetime(year, month, 1, 0, 0, 0)
        to_time = datetime(year, month+1, 1, 0, 0, 0)
        fname = "{0:06d}_{1:04d}_{2:02d}.csv".format(serial, year, month)
        reqs = {'gps_sensors_v2': self.gen_request(serial, from_time, to_time, 3),
                'gps': self.gen_request(serial, from_time, to_time, 3)}

        # Send each request to portal
        for k, r in reqs.items():
            fpath = os.path.join(self.config[k+'_local'], fname)
            response = self.s.post(self.url, data=r)

            # Download file if request is successful
            if response.status_code == 200:
                with open(fpath, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=128):
                        f.write(chunk)

                # Delete file if it's empty (i.e. only contains the header)
                if wccount(fpath) == 1:
                    os.remove(fpath)
                    print("Skipped {}".format(fpath))
                else:
                    print("Saved {}".format(fpath))
