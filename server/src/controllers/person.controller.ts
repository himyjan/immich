import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Next,
  Param,
  Post,
  Put,
  Query,
  Res,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { NextFunction, Response } from 'express';
import { BulkIdResponseDto, BulkIdsDto } from 'src/dtos/asset-ids.response.dto';
import { AuthDto } from 'src/dtos/auth.dto';
import {
  AssetFaceUpdateDto,
  MergePersonDto,
  PeopleResponseDto,
  PeopleUpdateDto,
  PersonCreateDto,
  PersonResponseDto,
  PersonSearchDto,
  PersonStatisticsResponseDto,
  PersonUpdateDto,
} from 'src/dtos/person.dto';
import { Permission } from 'src/enum';
import { Auth, Authenticated, FileResponse } from 'src/middleware/auth.guard';
import { LoggingRepository } from 'src/repositories/logging.repository';
import { PersonService } from 'src/services/person.service';
import { sendFile } from 'src/utils/file';
import { UUIDParamDto } from 'src/validation';

@ApiTags('People')
@Controller('people')
export class PersonController {
  constructor(
    private service: PersonService,
    private logger: LoggingRepository,
  ) {
    this.logger.setContext(PersonController.name);
  }

  @Get()
  @Authenticated({ permission: Permission.PersonRead })
  getAllPeople(@Auth() auth: AuthDto, @Query() options: PersonSearchDto): Promise<PeopleResponseDto> {
    return this.service.getAll(auth, options);
  }

  @Post()
  @Authenticated({ permission: Permission.PersonCreate })
  createPerson(@Auth() auth: AuthDto, @Body() dto: PersonCreateDto): Promise<PersonResponseDto> {
    return this.service.create(auth, dto);
  }

  @Put()
  @Authenticated({ permission: Permission.PersonUpdate })
  updatePeople(@Auth() auth: AuthDto, @Body() dto: PeopleUpdateDto): Promise<BulkIdResponseDto[]> {
    return this.service.updateAll(auth, dto);
  }

  @Delete()
  @HttpCode(HttpStatus.NO_CONTENT)
  @Authenticated({ permission: Permission.PersonDelete })
  deletePeople(@Auth() auth: AuthDto, @Body() dto: BulkIdsDto): Promise<void> {
    return this.service.deleteAll(auth, dto);
  }

  @Get(':id')
  @Authenticated({ permission: Permission.PersonRead })
  getPerson(@Auth() auth: AuthDto, @Param() { id }: UUIDParamDto): Promise<PersonResponseDto> {
    return this.service.getById(auth, id);
  }

  @Put(':id')
  @Authenticated({ permission: Permission.PersonUpdate })
  updatePerson(
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
    @Body() dto: PersonUpdateDto,
  ): Promise<PersonResponseDto> {
    return this.service.update(auth, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @Authenticated({ permission: Permission.PersonDelete })
  deletePerson(@Auth() auth: AuthDto, @Param() { id }: UUIDParamDto): Promise<void> {
    return this.service.delete(auth, id);
  }

  @Get(':id/statistics')
  @Authenticated({ permission: Permission.PersonStatistics })
  getPersonStatistics(@Auth() auth: AuthDto, @Param() { id }: UUIDParamDto): Promise<PersonStatisticsResponseDto> {
    return this.service.getStatistics(auth, id);
  }

  @Get(':id/thumbnail')
  @FileResponse()
  @Authenticated({ permission: Permission.PersonRead })
  async getPersonThumbnail(
    @Res() res: Response,
    @Next() next: NextFunction,
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
  ) {
    await sendFile(res, next, () => this.service.getThumbnail(auth, id), this.logger);
  }

  @Put(':id/reassign')
  @Authenticated({ permission: Permission.PersonReassign })
  reassignFaces(
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
    @Body() dto: AssetFaceUpdateDto,
  ): Promise<PersonResponseDto[]> {
    return this.service.reassignFaces(auth, id, dto);
  }

  @Post(':id/merge')
  @Authenticated({ permission: Permission.PersonMerge })
  mergePerson(
    @Auth() auth: AuthDto,
    @Param() { id }: UUIDParamDto,
    @Body() dto: MergePersonDto,
  ): Promise<BulkIdResponseDto[]> {
    return this.service.mergePerson(auth, id, dto);
  }
}
