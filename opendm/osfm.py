"""
OpenSfM related utils
"""

import os, shutil, sys
from opendm import io
from opendm import log
from opendm import system
from opendm import context

class OSFMContext:
    def __init__(self, opensfm_project_path):
        self.opensfm_project_path = opensfm_project_path

    def run(self, command):
        system.run('opensfm %s %s' %
                    (command, self.opensfm_project_path))

    def export_bundler(self, destination_bundle_file, rerun=False):
        if not io.file_exists(destination_bundle_file) or rerun:
                # convert back to bundler's format
                system.run('%s/bin/export_bundler %s' %
                        (context.opensfm_path, self.opensfm_project_path))
        else:
            log.ODM_WARNING('Found a valid Bundler file in: %s' % destination_bundle_file)

    def reconstruct(self, rerun=False):
        tracks_file = os.path.join(self.opensfm_project_path, 'tracks.csv')
        reconstruction_file = os.path.join(self.opensfm_project_path, 'reconstruction.json')

        if not io.file_exists(tracks_file) or rerun:
            self.run('create_tracks')
        else:
            log.ODM_WARNING('Found a valid OpenSfM tracks file in: %s' % tracks_file)

        if not io.file_exists(reconstruction_file) or rerun:
            self.run('reconstruct')
        else:
            log.ODM_WARNING('Found a valid OpenSfM reconstruction file in: %s' % reconstruction_file)

        # Check that a reconstruction file has been created
        if not io.file_exists(reconstruction_file):
            log.ODM_ERROR("The program could not process this dataset using the current settings. "
                            "Check that the images have enough overlap, "
                            "that there are enough recognizable features "
                            "and that the images are in focus. "
                            "You could also try to increase the --min-num-features parameter."
                            "The program will now exit.")
            raise Exception("Reconstruction could not be generated")


    def setup(self, args, images_path, photos, gcp_path=None, append_config = [], rerun=False):
        """
        Setup a OpenSfM project
        """
        if rerun and io.dir_exists(self.opensfm_project_path):
            shutil.rmtree(self.opensfm_project_path)

        if not io.dir_exists(self.opensfm_project_path):
            system.mkdir_p(self.opensfm_project_path)

        list_path = io.join_paths(self.opensfm_project_path, 'image_list.txt')
        if not io.file_exists(list_path) or rerun:

            # create file list
            has_alt = True
            with open(list_path, 'w') as fout:
                for photo in photos:
                    if not photo.altitude:
                        has_alt = False
                    fout.write('%s\n' % io.join_paths(images_path, photo.filename))

            # create config file for OpenSfM
            config = [
                "use_exif_size: no",
                "feature_process_size: %s" % args.resize_to,
                "feature_min_frames: %s" % args.min_num_features,
                "processes: %s" % args.max_concurrency,
                "matching_gps_neighbors: %s" % args.matcher_neighbors,
                "depthmap_method: %s" % args.opensfm_depthmap_method,
                "depthmap_resolution: %s" % args.depthmap_resolution,
                "depthmap_min_patch_sd: %s" % args.opensfm_depthmap_min_patch_sd,
                "depthmap_min_consistent_views: %s" % args.opensfm_depthmap_min_consistent_views,
                "optimize_camera_parameters: %s" % ('no' if args.use_fixed_camera_params else 'yes')
            ]

            if has_alt:
                log.ODM_DEBUG("Altitude data detected, enabling it for GPS alignment")
                config.append("use_altitude_tag: yes")
                config.append("align_method: naive")
            else:
                config.append("align_method: orientation_prior")
                config.append("align_orientation_prior: vertical")

            if args.use_hybrid_bundle_adjustment:
                log.ODM_DEBUG("Enabling hybrid bundle adjustment")
                config.append("bundle_interval: 100")          # Bundle after adding 'bundle_interval' cameras
                config.append("bundle_new_points_ratio: 1.2")  # Bundle when (new points) / (bundled points) > bundle_new_points_ratio
                config.append("local_bundle_radius: 1")        # Max image graph distance for images to be included in local bundle adjustment

            if args.matcher_distance > 0:
                config.append("matching_gps_distance: %s" % args.matcher_distance)

            if gcp_path:
                config.append("bundle_use_gcp: yes")
                io.copy(gcp_path, self.path("gcp_list.txt"))

            config = config + append_config

            # write config file
            log.ODM_DEBUG(config)
            config_filename = io.join_paths(self.opensfm_project_path, 'config.yaml')
            with open(config_filename, 'w') as fout:
                fout.write("\n".join(config))

            # check for image_groups.txt (split-merge)
            image_groups_file = os.path.join(args.project_path, "image_groups.txt")
            if io.file_exists(image_groups_file):
                log.ODM_DEBUG("Copied image_groups.txt to OpenSfM directory")
                io.copy(image_groups_file, os.path.join(self.opensfm_project_path, "image_groups.txt"))
        else:
            log.ODM_WARNING("%s already exists, not rerunning OpenSfM setup" % list_path)

    def extract_metadata(self, rerun=False):
        metadata_dir = self.path("exif")
        if not io.dir_exists(metadata_dir) or rerun:
            self.run('extract_metadata')

    def feature_matching(self, rerun=False):
        features_dir = self.path("features")
        matches_dir = self.path("matches")

        if not io.dir_exists(features_dir) or rerun:
            self.run('detect_features')
        else:
            log.ODM_WARNING('Detect features already done: %s exists' % features_dir)

        if not io.dir_exists(matches_dir) or rerun:
            self.run('match_features')
        else:
            log.ODM_WARNING('Match features already done: %s exists' % matches_dir)


    def path(self, *paths):
        return os.path.join(self.opensfm_project_path, *paths)

    def save_absolute_image_list_to(self, file):
        """
        Writes a copy of the image_list.txt file and makes sure that all paths
        written in it are absolute paths and not relative paths.
        """
        image_list_file = self.path("image_list.txt")

        if io.file_exists(image_list_file):
            with open(image_list_file, 'r') as f:
                content = f.read()

            lines = []
            for line in map(str.strip, content.split('\n')):
                if line and not line.startswith("/"):
                    line = os.path.abspath(os.path.join(self.opensfm_project_path, line))
                lines.append(line)

            with open(file, 'w') as f:
                f.write("\n".join(lines))

            log.ODM_DEBUG("Wrote %s with absolute paths" % file)
        else:
            log.ODM_WARNING("No %s found, cannot create %s" % (image_list_file, file))

    def name(self):
        return os.path.basename(os.path.abspath(self.path("..")))

def get_submodel_argv(project_name = None, submodels_path = None, submodel_name = None):
    """
    Gets argv for a submodel starting from the argv passed to the application startup.
    Additionally, if project_name, submodels_path and submodel_name are passed, the function
    handles the <project name> value and --project-path detection / override.
    When all arguments are set to None, --project-path and project name are always removed.

    :return the same as argv, but removing references to --split,
        setting/replacing --project-path and name
        removing --rerun-from, --rerun, --rerun-all, --sm-cluster
        adding --orthophoto-cutline
        adding --dem-euclidean-map
        adding --skip-3dmodel (split-merge does not support 3D model merging)
        removing --gcp (the GCP path if specified is always "gcp_list.txt")
    """
    assure_always = ['--orthophoto-cutline', '--dem-euclidean-map', '--skip-3dmodel']
    remove_always_2 = ['--split', '--split-overlap', '--rerun-from', '--rerun', '--gcp', '--end-with', '--sm-cluster']
    remove_always_1 = ['--rerun-all']

    argv = sys.argv

    result = [argv[0]]
    i = 1
    found_args = {}

    while i < len(argv):
        arg = argv[i]

        # Last?
        if i == len(argv) - 1:
            # Project name?
            if project_name and submodel_name and arg == project_name:
                result.append(submodel_name)
                found_args['project_name'] = True
            elif arg.startswith("--"):
                result.append(arg)
            i += 1
        elif arg == '--project-path':
            if submodels_path:
                result.append(arg)
                result.append(submodels_path)
                found_args[arg] = True
            i += 2
        elif arg in assure_always:
            result.append(arg)
            found_args[arg] = True
            i += 1
        elif arg in remove_always_2:
            i += 2
        elif arg in remove_always_1:
            i += 1
        else:
            result.append(arg)
            i += 1

    if not found_args.get('--project-path') and submodels_path:
        result.append('--project-path')
        result.append(submodels_path)

    if not found_args.get('project_name') and submodel_name:
        result.append(submodel_name)

    for arg in assure_always:
        if not found_args.get(arg):
            result.append(arg)

    return result

def get_submodel_args_dict():
    submodel_argv = get_submodel_argv()
    result = {}

    i = 0
    while i < len(submodel_argv):
        arg = submodel_argv[i]
        next_arg = None if i == len(submodel_argv) - 1 else submodel_argv[i + 1]

        if next_arg and arg.startswith("--"):
            if next_arg.startswith("--"):
                result[arg[2:]] = True
            else:
                result[arg[2:]] = next_arg
                i += 1
        elif arg.startswith("--"):
            result[arg[2:]] = True
        i += 1

    return result


def get_submodel_paths(submodels_path, *paths):
    """
    :return Existing paths for all submodels
    """
    result = []
    if not os.path.exists(submodels_path):
        return result

    for f in os.listdir(submodels_path):
        if f.startswith('submodel'):
            p = os.path.join(submodels_path, f, *paths)
            if os.path.exists(p):
                result.append(p)
            else:
                log.ODM_WARNING("Missing %s from submodel %s" % (p, f))

    return result

def get_all_submodel_paths(submodels_path, *all_paths):
    """
    :return Existing, multiple paths for all submodels as a nested list (all or nothing for each submodel)
        if a single file is missing from the submodule, no files are returned for that submodel.

        (i.e. get_multi_submodel_paths("path/", "odm_orthophoto.tif", "dem.tif")) -->
                [["path/submodel_0000/odm_orthophoto.tif", "path/submodel_0000/dem.tif"],
                 ["path/submodel_0001/odm_orthophoto.tif", "path/submodel_0001/dem.tif"]]
    """
    result = []
    if not os.path.exists(submodels_path):
        return result

    for f in os.listdir(submodels_path):
        if f.startswith('submodel'):
            all_found = True

            for ap in all_paths:
                p = os.path.join(submodels_path, f, ap)
                if not os.path.exists(p):
                    log.ODM_WARNING("Missing %s from submodel %s" % (p, f))
                    all_found = False

            if all_found:
                result.append([os.path.join(submodels_path, f, ap) for ap in all_paths])

    return result
