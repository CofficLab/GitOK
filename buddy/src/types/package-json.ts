/**
 * NPM包信息接口
 */
export interface PackageJson {
    name: string;
    version: string;
    description?: string;
    keywords?: string[];
    date?: string;
    links?: NpmLinks;
    publisher?: NpmPublisher;
    maintainers?: NpmMaintainer[];
    scope?: string;
    page?: string;
    author?: string;
    main?: string;
}


/**
 * NPM包元数据接口
 */
export interface NpmPackageMetadata {
    name: string;
    'dist-tags': Record<string, string>;
    versions: Record<string, NpmPackageVersion>;
    time: Record<string, string>;
    maintainers: NpmMaintainer[];
    description?: string;
    homepage?: string;
    keywords?: string[];
    repository?: {
        type: string;
        url: string;
    };
    author?: string | {
        name: string;
        email?: string;
        url?: string;
    };
    bugs?: {
        url: string;
    };
    license?: string;
    readme?: string;
    readmeFilename?: string;
}


/**
 * NPM包版本信息
 */
export interface NpmPackageVersion {
    name: string;
    version: string;
    description?: string;
    main?: string;
    scripts?: Record<string, string>;
    repository?: {
        type: string;
        url: string;
    };
    keywords?: string[];
    author?: string | {
        name: string;
        email?: string;
        url?: string;
    };
    license?: string;
    bugs?: {
        url: string;
    };
    homepage?: string;
    dependencies?: Record<string, string>;
    devDependencies?: Record<string, string>;
    peerDependencies?: Record<string, string>;
    dist?: {
        shasum: string;
        tarball: string;
        integrity?: string;
        fileCount?: number;
        unpackedSize?: number;
        'npm-signature'?: string;
    };
}


/**
 * NPM包维护者信息
 */
export interface NpmMaintainer {
    name: string;
    email?: string;
    url?: string;
}

/**
 * NPM包发布者信息
 */
export interface NpmPublisher {
    username: string;
    email?: string;
}

/**
 * NPM包链接信息
 */
export interface NpmLinks {
    npm?: string;
    homepage?: string;
    repository?: string;
    bugs?: string;
}